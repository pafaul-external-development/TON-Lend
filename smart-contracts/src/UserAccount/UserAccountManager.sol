pragma ton-solidity >= 0.39.0;
pragma AbiHeader pubkey;
pragma AbiHeader expire;
pragma AbiHeader time;

import "./interfaces/IUserAccountManager.sol";
import "./interfaces/IUAMUserAccount.sol";
import "./interfaces/IUAMMarket.sol";

import "./libraries/UserAccountErrorCodes.sol";

import "../Market/interfaces/IMarketInterfaces.sol";

import "../Controllers/interfaces/ICCCodeManager.sol";
import "../Controllers/libraries/PlatformCodes.sol";

import "../utils/interfaces/IUpgradableContract.sol";
import "../utils/libraries/MsgFlag.sol";
import "../utils/Platform/Platform.sol";

contract UserAccountManager is IUpgradableContract, IUserAccountManager, IUAMUserAccount, IUAMMarket {
    // Information for update
    address root;
    uint8 contractType;
    uint32 contractCodeVersion;
    TvmCell platformCode;

    address marketAddress;
    mapping(uint8 => address) modules;

    /*********************************************************************************************************/
    // Functions to add/remove modules info
    function addModule(uint8 operationId, address module) external onlyMarket {
        modules[operationId] = module;
    }

    function deleteModule(uint8 operationId) external onlyMarket {
        delete modules[operationId];
    }

    /*********************************************************************************************************/
    // Functions for deployment and upgrade
    // Contract is deployed via platform
    constructor() public { revert(); }

    /*  Upgrade Data for version 1 (from version 0):
        bits:
            address root
            uint8 contractType
            uint32 codeVersion
        refs:
            1. platformCode
            2. additionalData:
            bits:
                1. address marketAddress
            refs:
                1. mapping(uint32 => bool) marketIds
     */
    function upgradeContractCode(TvmCell code, TvmCell updateParams, uint32 codeVersion_, uint8 contractType_) override external onlyRoot correctContractType(contractType_) {
        tvm.accept();

        contractCodeVersion = codeVersion_;

        TvmBuilder builder;
        builder.store(root);
        builder.store(contractType);
        builder.store(codeVersion_);
        builder.store(platformCode);

        TvmBuilder additionalData;
        additionalData.store(marketAddress);

        TvmBuilder mappingData;
        mappingData.store(marketIds);
        additionalData.store(mappingData.toCell());

        tvm.setcode(code);
        tvm.setCurrentCode(code);

        onCodeUpgrade(builder.toCell());
    }

    /*  Upgrade Data for version 0 (from Platform):
        bits:
            address root
            uint8 platformType
        refs:
            1. platformCode
            2. initialData
            bits:
                1. marketAddress
     */
    function onCodeUpgrade(TvmCell data) private {
        tvm.resetStorage();
        TvmSlice dataSlice = data.toSlice();
        (root, contractType) = dataSlice.decode(address, uint8);

        platformCode = dataSlice.loadRef();         // Loading platform code
        TvmSlice addressData = dataSlice.loadRefAsSlice();
        (marketAddress) = addressData.decode(address);
    }

    /*********************************************************************************************************/
    // Functions for user account
    /**
     * @param tonWallet Address of user's ton wallet
     */
    function createUserAccount(address tonWallet) external override view {
        TvmCell empty;
        IContractControllerCodeManager(root).createContract{
            value: 0,
            bounce: false,
            flag: MsgFlag.REMAINING_GAS
        }(PlatformCodes.USER_ACCOUNT, _buildUserAccountInitialData(tonWallet), empty);
    }

    // address calculation functions
    /**
     * @param tonWallet Address of user's ton wallet
     */
    function calculateUserAccountAddress(address tonWallet) external override responsible view returns (address) {
        return { value: 0, bounce: false, flag: MsgFlag.REMAINING_GAS } _calculateUserAccountAddress(tonWallet);
    }

    /**
     * @param tonWallet Address of user's ton wallet
     */
    function _calculateUserAccountAddress(address tonWallet) internal view returns(address) {
        return address(tvm.hash(_buildUserAccountData(tonWallet)));
    }

    /**
     * @param tonWallet Address of user's ton wallet
     */
    function _buildUserAccountData(address tonWallet) private view returns (TvmCell data) {
        TvmCell userData = _buildUserAccountInitialData(tonWallet);
        return tvm.buildStateInit({
            contr: Platform,
            varInit: {
                root: root,
                platformType: PlatformCodes.USER_ACCOUNT,
                platformCode: platformCode,
                initialData: userData
            },
            pubkey: 0,
            code: platformCode
        });
    }

    /**
     * @param tonWallet Address of user's ton wallet
     */
    function _buildUserAccountInitialData(address tonWallet) private pure returns (TvmCell data) {
        TvmBuilder userData;
        userData.store(tonWallet);
        return userData.toCell();
    }

    /*********************************************************************************************************/
    // Supply operations

    function writeSupplyInfo(address tonWallet, address userTip3Wallet, uint32 marketId, uint256 tokensToSupply, fraction index) external override view onlyMarket {
        address userAccount = _calculateUserAccountAddress(tonWallet);
        IUserAccountData(userAccount).writeSupplyInfo{
            flag: MsgFlag.REMAINING_GAS
        }(userTip3Wallet, marketId, tokensToSupply, index);
    }

    function requestVTokenMint(address tonWallet, address userTip3Wallet, uint32 marketId, uint256 toMint) external override view onlyValidUserAccount(tonWallet) {
        IMarketOperations(marketAddress).mintVTokens{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, userTip3Wallet, marketId, toMint);
    }

    /*********************************************************************************************************/
    // Withdraw operations

    function requestWithdrawInfo(address tonWallet, address userTip3Wallet, address originalTip3Wallet, uint256 tokensToWithdraw, uint32 marketId, mapping(uint32 => fraction) updatedIndexes) external override view {
        address userAccount = _calculateUserAccountAddress(tonWallet);
        IUserAccountData(userAccount).requestWithdrawInfo{
            flag: MsgFlag.REMAINING_GAS
        }(userTip3Wallet, originalTip3Wallet, marketId, tokensToWithdraw, updatedIndexes);
    }

    function receiveWithdrawInfo(address tonWallet, address userTip3Wallet, address originalTip3Wallet, uint256 tokensToWithdraw, uint32 marketId, mapping(uint32 => uint256) si, mapping(uint32 => uint256) bi) external override view onlyValidUserAccount(tonWallet) {
        IMarketOperations(marketAddress).withdrawTokensFromMarket{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, userTip3Wallet, originalTip3Wallet, marketId, tokensToWithdraw, bi, si);
    }

    function writeWithdrawInfo(address tonWallet, address userTip3Wallet, uint32 marketId, uint256 tokensToWithdraw, uint256 tokensToSend) external override view onlyMarket {
        address userAccount = _calculateUserAccountAddress(tonWallet); 
        IUserAccountData(userAccount).writeWithdrawInfo{
            flag: MsgFlag.REMAINING_GAS
        }(userTip3Wallet, marketId, tokensToWithdraw, tokensToSend);
    }

    /*********************************************************************************************************/
    // Borrow operations

    function requestIndexUpdate(address tonWallet, uint32 marketId, mapping(uint32 => bool) knownMarkets, address userTip3Wallet, uint256 amountToBorrow) external override view onlyValidUserAccount(tonWallet) {
        IMarketOperations(marketAddress).requestIndexUpdate{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, marketId, knownMarkets, userTip3Wallet, amountToBorrow);
    }

    function updateUserIndexes(address tonWallet, uint32 marketId, mapping(uint32 => fraction) updatedIndexes, address userTip3Wallet, uint256 toBorrow) external override view onlyMarket {
        address userAccount = _calculateUserAccountAddress(tonWallet);
        IUserAccountData(userAccount).updateIndexes{
            flag: MsgFlag.REMAINING_GAS
        }(marketId, updatedIndexes, userTip3Wallet, toBorrow);
    }

    function passBorrowInformation(address tonWallet, address userTip3Wallet, uint32 marketId, uint256 toBorrow, mapping(uint32 => uint256) borrowInfo, mapping(uint32 => uint256) supplyInfo) external override view onlyValidUserAccount(tonWallet) {
        IMarketOperations(marketAddress).receiveBorrowInformation{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, marketId, userTip3Wallet, toBorrow, borrowInfo, supplyInfo);
    }

    function writeBorrowInformation(address tonWallet, uint32 marketId, uint256 toBorrow, address userTip3Wallet, fraction index) external override view onlyMarket {
        address userAccount = _calculateUserAccountAddress(tonWallet);
        IUserAccountData(userAccount).writeBorrowInformation{
            flag: MsgFlag.REMAINING_GAS
        }(marketId, toBorrow, userTip3Wallet, index);
    }

    /*********************************************************************************************************/
    // Repay operations

    function requestRepayInfo(address tonWallet, address userTip3Wallet, address originalTip3Wallet, uint256 tokensForRepay, uint32 marketId, uint8 loanId, mapping(uint32 => fraction) updatedIndexes) external override view onlyMarket {
        address userAccount = _calculateUserAccountAddress(tonWallet);
        IUserAccountData(userAccount).sendRepayInfo{
            flag: MsgFlag.REMAINING_GAS
        }(userTip3Wallet, originalTip3Wallet, tokensForRepay, marketId, loanId, updatedIndexes);
    }

    function sendRepayInfo(address tonWallet, address userTip3Wallet, uint32 marketId, uint8 loanId, uint256 tokensForRepay, BorrowInfo bi) external override view onlyValidUserAccount(tonWallet) {
        IMarketOperations(marketAddress).receiveRepayInformation{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, userTip3Wallet, marketId, loanId, tokensForRepay, bi);
    }

    function writeRepayInformation(address tonWallet, address userTip3Wallet, uint32 marketId, uint8 loanId, uint256 tokensToReturn, BorrowInfo bi) external override view onlyMarket {
        address userAccount = _calculateUserAccountAddress(tonWallet);
        IUserAccountData(userAccount).writeRepayInformation{
            flag: MsgFlag.REMAINING_GAS
        }(userTip3Wallet, marketId, loanId, tokensToReturn, bi);
    }

    /*********************************************************************************************************/
    // Requests from user account to market

    function requestTokenPayout(address tonWallet, address userTip3Wallet, uint32 marketId, uint256 toPayout) external override view onlyValidUserAccount(tonWallet) {
        IMarketOperations(marketAddress).requestTokenPayout{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, userTip3Wallet, marketId, toPayout);
    }

    /*********************************************************************************************************/
    // Market managing functions

    /**
     * @param market_ Address of market smart contract
     */
    function setMarketAddress(address market_) external override onlyRoot {
        tvm.accept();
        marketAddress = market_;
    }

    /**
     * @param marketId Id of market to add to known
     */
    function addMarket(uint32 marketId) external override onlyRoot {
        tvm.accept();
        marketIds[marketId] = true;
    }

    /**
     * @param marketId Id of market to remove from known
     */
    function removeMarket(uint32 marketId) external override onlyRoot {
        tvm.accept();
        delete marketIds[marketId];
    }


    /*********************************************************************************************************/
    // modifiers
    // TODO: add error codes
    modifier onlyRoot() {
        require(msg.sender == root, UserAccountErrorCodes.ERROR_NOT_ROOT);
        _;
    }

    modifier onlyMarket() {
        require(msg.sender == marketAddress);
        tvm.rawReserve(msg.value, 2);
        _;
    }

    /**
     * @param tonWallet Address of user's ton wallet
     */
    modifier onlyValidUserAccount(address tonWallet) {
        require(msg.sender == _calculateUserAccountAddress(tonWallet));
        tvm.rawReserve(msg.value, 2);
        _;
    }

    /**
     * @param contractType_ Type of contract
     */
    modifier correctContractType(uint8 contractType_) {
        require(contractType == contractType_, UserAccountErrorCodes.ERROR_INVALID_CONTRACT_TYPE);
        _;
    }
}