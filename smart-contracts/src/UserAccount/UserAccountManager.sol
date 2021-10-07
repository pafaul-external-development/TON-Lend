pragma ton-solidity >= 0.43.0;
pragma AbiHeader pubkey;
pragma AbiHeader expire;
pragma AbiHeader time;

import "./interfaces/IUserAccountManager.sol";
import "./interfaces/IUAMUserAccount.sol";
import "./interfaces/IUAMMarket.sol";

import "./libraries/UserAccountErrorCodes.sol";
import './libraries/CostConstants.sol';

import "../Market/interfaces/IMarketInterfaces.sol";

import "../WalletController/libraries/OperationCodes.sol";

import "../Controllers/interfaces/ICCCodeManager.sol";
import "../Controllers/libraries/PlatformCodes.sol";

import "../utils/interfaces/IUpgradableContract.sol";
import "../utils/libraries/MsgFlag.sol";

import './UserAccount.sol';

contract UserAccountManager is IUpgradableContract, IUserAccountManager, IUAMUserAccount, IUAMMarket {
    // Information for update
    uint32 public contractCodeVersion;

    address public owner;

    address public marketAddress;
    mapping(uint8 => address) public modules;
    mapping(address => bool) public existingModules;
    mapping(uint32 => TvmCell) public userAccountCodes;

    /*********************************************************************************************************/
    // Functions for deployment and upgrade
    // Contract is deployed via platform
    constructor(address _owner) public {
        tvm.accept();
        owner = _owner;
    }

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
    function upgradeContractCode(TvmCell code, TvmCell updateParams, uint32 codeVersion) override external onlyOwner {
        tvm.accept();

        tvm.setcode(code);
        tvm.setCurrentCode(code);

        onCodeUpgrade(
            marketAddress,
            modules,
            existingModules,
            userAccountCodes,
            updateParams,
            codeVersion
        );
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
    function onCodeUpgrade(
        address,
        mapping(uint8 => address),
        mapping(address => bool),
        mapping(uint32 => TvmCell),
        TvmCell,
        uint32
    ) private {
        tvm.accept();
    }

    /*********************************************************************************************************/
    // Functions for user account
    /**
     * @param tonWallet Address of user's ton wallet
     */
    function createUserAccount(address tonWallet) external override view responsible returns(address) {
        tvm.rawReserve(msg.value, 2);

        TvmSlice ts = userAccountCodes[0].toSlice();
        require(!ts.empty());

        address userAccount = new UserAccount{
            value: UserAccountCostConstants.useForUADeploy,
            code: userAccountCodes[0],
            pubkey: 0,
            varInit: {
                owner: tonWallet
            }
        }();

        return userAccount;
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
        return tvm.buildStateInit({
            contr: UserAccount,
            varInit: {
                owner: tonWallet
            },
            pubkey: 0,
            code: userAccountCodes[0]
        });
    }

    /*********************************************************************************************************/
    // Supply operations

    function writeSupplyInfo(
        address tonWallet,
        uint32 marketId, 
        uint256 tokensToSupply, 
        fraction index
    ) external override view onlyModule(OperationCodes.SUPPLY_TOKENS) {
        address userAccount = _calculateUserAccountAddress(tonWallet);
        IUserAccountData(userAccount).writeSupplyInfo{
            flag: MsgFlag.REMAINING_GAS
        }(marketId, tokensToSupply, index);
    }

    /*********************************************************************************************************/
    // Withdraw operations

    function requestWithdrawInfo(
        address tonWallet, 
        address userTip3Wallet,
        uint256 tokensToWithdraw, 
        uint32 marketId, 
        mapping(uint32 => fraction) updatedIndexes
    ) external override view onlyModule(OperationCodes.WITHDRAW_TOKENS) {
        address userAccount = _calculateUserAccountAddress(tonWallet);
        IUserAccountData(userAccount).requestWithdrawInfo{
            flag: MsgFlag.REMAINING_GAS
        }(userTip3Wallet, marketId, tokensToWithdraw, updatedIndexes);
    }

    function receiveWithdrawInfo(
        address tonWallet, 
        address userTip3Wallet,
        uint256 tokensToWithdraw,
        uint32 marketId,
        mapping(uint32 => uint256) si,
        mapping(uint32 => uint256) bi
    ) external override view onlyValidUserAccount(tonWallet) {
        IWithdrawModule(modules[OperationCodes.WITHDRAW_TOKENS]).withdrawTokensFromMarket{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, userTip3Wallet, tokensToWithdraw, marketId, bi, si);
    }

    function writeWithdrawInfo(
        address tonWallet, 
        address userTip3Wallet, 
        uint32 marketId, 
        uint256 tokensToWithdraw, 
        uint256 tokensToSend
    ) external override view onlyModule(OperationCodes.WITHDRAW_TOKENS) {
        address userAccount = _calculateUserAccountAddress(tonWallet); 
        IUserAccountData(userAccount).writeWithdrawInfo{
            flag: MsgFlag.REMAINING_GAS
        }(userTip3Wallet, marketId, tokensToWithdraw, tokensToSend);
    }

    /*********************************************************************************************************/
    // Borrow operations

    function requestIndexUpdate(
        address tonWallet, 
        uint32 marketId, 
        TvmCell args
    ) external override view onlyValidUserAccount(tonWallet) {
        IMarketOperations(marketAddress).performOperationUserAccountManager{
            flag: MsgFlag.REMAINING_GAS
        }(OperationCodes.BORROW_TOKENS, marketId, args);
    }

    function updateUserIndexes(
        address tonWallet, 
        address userTip3Wallet, 
        uint256 tokensToBorrow, 
        uint32 marketId,
        mapping(uint32 => fraction) updatedIndexes
    ) external override view onlyModule(OperationCodes.BORROW_TOKENS) {
        address userAccount = _calculateUserAccountAddress(tonWallet);
        IUserAccountData(userAccount).borrowUpdateIndexes{
            flag: MsgFlag.REMAINING_GAS
        }(marketId, updatedIndexes, userTip3Wallet, tokensToBorrow);
    }

    function passBorrowInformation(
        address tonWallet, 
        address userTip3Wallet, 
        uint32 marketId, 
        uint256 tokensToBorrow, 
        mapping(uint32 => uint256) borrowInfo, 
        mapping(uint32 => uint256) supplyInfo
    ) external override view onlyValidUserAccount(tonWallet) {
        IBorrowModule(modules[OperationCodes.BORROW_TOKENS]).borrowTokensFromMarket{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, userTip3Wallet, tokensToBorrow, marketId, supplyInfo, borrowInfo);
    }

    function writeBorrowInformation(
        address tonWallet, 
        address userTip3Wallet, 
        uint256 tokensToBorrow, 
        uint32 marketId, 
        fraction index
    ) external override view onlyModule(OperationCodes.BORROW_TOKENS) {
        address userAccount = _calculateUserAccountAddress(tonWallet);
        IUserAccountData(userAccount).writeBorrowInformation{
            flag: MsgFlag.REMAINING_GAS
        }(marketId, tokensToBorrow, userTip3Wallet, index);
    }

    /*********************************************************************************************************/
    // Repay operations

    function requestRepayInfo(
        address tonWallet, 
        address userTip3Wallet, 
        uint256 tokensForRepay, 
        uint32 marketId,
        mapping(uint32 => fraction) updatedIndexes
    ) external override view onlyModule(OperationCodes.REPAY_TOKENS) {
        address userAccount = _calculateUserAccountAddress(tonWallet);
        IUserAccountData(userAccount).sendRepayInfo{
            flag: MsgFlag.REMAINING_GAS
        }(userTip3Wallet, marketId, tokensForRepay, updatedIndexes);
    }

    function receiveRepayInfo(
        address tonWallet, 
        address userTip3Wallet, 
        uint256 tokensForRepay,
        uint32 marketId,
        BorrowInfo borrowInfo
    ) external override view onlyValidUserAccount(tonWallet) {
        IRepayModule(modules[OperationCodes.REPAY_TOKENS]).repayLoan{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, userTip3Wallet, tokensForRepay, marketId, borrowInfo);
    }

    function writeRepayInformation(
        address tonWallet, 
        address userTip3Wallet, 
        uint32 marketId,
        uint256 tokensToReturn, 
        BorrowInfo bi
    ) external override view onlyModule(OperationCodes.REPAY_TOKENS) {
        address userAccount = _calculateUserAccountAddress(tonWallet);
        IUserAccountData(userAccount).writeRepayInformation{
            flag: MsgFlag.REMAINING_GAS
        }(userTip3Wallet, marketId, tokensToReturn, bi);
    }

    /*********************************************************************************************************/
    // Liquidation

    function calculateUserAccountHealth(address tonWallet, mapping(uint32 => uint256) supplyInfo, mapping(uint32 => BorrowInfo) borrowInfo) external override onlyValidUserAccount(tonWallet) {
        tvm.rawReserve(msg.value, 2);
        IMarketOperations(marketAddress).calculateUserAccountHealth{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, supplyInfo, borrowInfo);
    }

    function updateUserAccountHealth(address tonWallet, fraction accountHealth, mapping(uint32 => fraction) updatedIndexes) external override onlyMarket {
        tvm.rawReserve(msg.value, 2);
        address userAccount = _calculateUserAccountAddress(tonWallet);
        IUserAccountData(userAccount).updateUserAccountHealth{
            flag: MsgFlag.REMAINING_GAS
        }(accountHealth, updatedIndexes);
    }
 

    function markForLiquidation(address tonWallet) external override view onlyModules {

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
     * @param _market Address of market smart contract
     */
    function setMarketAddress(address _market) external override onlyOwner {
        tvm.accept();
        marketAddress = _market;
    }

    /*********************************************************************************************************/
    // Function for userAccountCode
    function uploadUserAccountCode(uint32 version, TvmCell code) external override {
        require(
            !userAccountCodes.exists(version)
        );
        userAccountCodes[version] = code;
        
        address(msg.sender).transfer({flag: MsgFlag.REMAINING_GAS, value: 0});
    }

    function updateUserAccount(address tonWallet) external override {
        tvm.rawReserve(msg.value, 2);
        address userAccount = _calculateUserAccountAddress(tonWallet);
        optional(uint32, TvmCell) latestVersion = userAccountCodes.max();
        if (latestVersion.hasValue()) {
            TvmCell empty;
            (uint32 codeVersion, TvmCell code) = latestVersion.get();
            IUpgradableContract(userAccount).upgradeContractCode{
                flag: MsgFlag.REMAINING_GAS
            }(code, empty, codeVersion);
        } else {
            address(msg.sender).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
        }
    }

    function getUserAccountCode(uint32 version) external override view responsible returns(TvmCell) {
        return {flag: MsgFlag.REMAINING_GAS} userAccountCodes[version];
    }

    /*********************************************************************************************************/
    // Functions to add/remove modules info
    function addModule(uint8 operationId, address module) external override onlyTrusted {
        modules[operationId] = module;
        existingModules[module] = true;
    }

    function removeModule(uint8 operationId) external override onlyTrusted {
        delete existingModules[modules[operationId]];
        delete modules[operationId];
    }

    /*********************************************************************************************************/
    // modifiers
    // TODO: add error codes
    modifier onlyOwner() {
        require(msg.sender == owner, UserAccountErrorCodes.ERROR_NOT_ROOT);
        _;
    }

    modifier onlyMarket() {
        require(
            msg.sender == marketAddress
        );
        tvm.rawReserve(msg.value, 2);
        _;
    }

    modifier onlyTrusted() {
        require(
            msg.sender == owner ||
            msg.sender == marketAddress
        );
        _;
    }

    modifier onlyModules() {
        require(
            existingModules.exists(msg.sender)
        );
        _;
    }

    modifier onlyModule(uint8 operationId) {
        require(
            msg.sender == modules[operationId]
        );
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
}