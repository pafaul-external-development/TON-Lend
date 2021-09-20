pragma ton-solidity >= 0.39.0;
pragma AbiHeader pubkey;
pragma AbiHeader expire;
pragma AbiHeader time;

import "./interfaces/IUserAccount.sol";
import "./libraries/UserAccountErrorCodes.sol";

import "./interfaces/IUAMUserAccount.sol";

import "../utils/interfaces/IUpgradableContract.sol";
import "../utils/libraries/MsgFlag.sol";

contract UserAccount is IUserAccount, IUserAccountData, IUpgradableContract {
    using UFO for uint256;
    using FPO for fraction;
    using ManageMapping for mapping(uint8 => BorrowInfo);

    bool borrowingAllowed;

    address owner;
    
    // Used for interactions with market 
    address userAccountManager;

    // Information for update
    address root;
    uint8 contractType;
    uint32 contractCodeVersion;
    TvmCell platformCode;

    mapping(uint32 => bool) knownMarkets;
    mapping(uint32 => UserMarketInfo) markets;

    // Contract is deployed via platform
    constructor() public { 
        revert(); 
    }

    /*  Upgrade Data for version 0 (from Platform):
        bits:
            address root
            uint8 platformType
            address gasTo ?
        refs:
            1. platformCode
            2. initialData
                bits:
                    address owner
                    address userAccountManager
     */
    function onCodeUpgrade(TvmCell data) private {
        tvm.resetStorage();
        TvmSlice dataSlice = data.toSlice();
        address sendGasTo;
        (root, contractType, sendGasTo) = dataSlice.decode(address, uint8, address);
        contractCodeVersion = 0;

        platformCode = dataSlice.loadRef();         // Loading platform code
        TvmSlice ownerData = dataSlice.loadRefAsSlice();
        (owner, userAccountManager) = ownerData.decode(address, address);

        borrowingAllowed = true;
    }

    /*  Upgrade data for version 1 (from 0):
        bits:
            address root
            uint8 platformType
            uint32 contractVersion
        refs:
            1. TvmCell platformCode
            2. user data:
                bits:
                    address owner
                    address userAccountManager
                refs:
                    1. mapping(address => TvmCell) userData
     */
    function upgradeContractCode(TvmCell code, TvmCell updateParams, uint32 codeVersion_, uint8 contractType_) override external onlyRoot correctContractType(contractType_) {
        contractCodeVersion = codeVersion_;

        TvmBuilder builder;
        builder.store(root);
        builder.store(contractType);
        builder.store(codeVersion_);
        builder.store(platformCode);

        TvmBuilder userDataBuilder;
        userDataBuilder.store(owner);
        userDataBuilder.store(userAccountManager);

        TvmBuilder userDataMapping;
        userDataMapping.store(markets);
        userDataBuilder.store(userDataMapping.toCell());
        builder.store(userDataBuilder.toCell());

        tvm.setcode(code);
        tvm.setCurrentCode(code);

        onCodeUpgrade(builder.toCell());
    }

    function getOwner() external override responsible view returns(address) {
        return { value: 0, bounce: false, flag: MsgFlag.REMAINING_GAS } owner;
    }

    /*********************************************************************************************************/
    // Supply functions

    function writeSupplyInfo(address userTip3Wallet, uint32 marketId_, uint256 tokensToSupply, fraction index) external override onlyUserAccountManager {
        markets[marketId_].suppliedTokens += tokensToSupply;
        _updateMarketInfo(marketId_, index);
        IUAMUserAccount(userAccountManager).requestVTokenMint{
            flag: MsgFlag.REMAINING_GAS
        }(owner, userTip3Wallet, marketId_, tokensToSupply);
    }

    /*********************************************************************************************************/
    // Withdraw functions

    function requestWithdrawalInfo(address tonWallet, address userTip3Wallet, address originalTip3Wallet, uint32 marketId_, uint256 tokenAmount) external override onlyMarket {
        address userAccount = _calculateUserAccountAddress(tonWallet);
        IUAMUserAccount(userAccount).requestWithdrawalInfo{
            flag: MsgFlag.REMAINING_GAS
        }(userTip3Wallet, originalTip3Wallet, marketId_, tokenAmount);
    }

    function writeWithdrawInfo(address userTip3Wallet, uint32 marketId, uint256 tokensToWithdraw, uint256 tokensToSend, mapping(uint32 => fraction) updatedIndexes) external override onlyUserAccountManager{
        
    }

    function updateIndexesAndReturnTokens(address originalTip3Wallet, uint32 marketId, uint256 tokensToWithdraw, mapping(uint32 => fraction) updatedIndexes) external override onlyUserAccountManager {

    }

    /*********************************************************************************************************/
    // Borrow functions

    function borrow(uint32 marketId, uint256 amountToBorrow, address userTip3Wallet) external override onlyOwner {
        tvm.rawReserve(msg.value, 2);
        if (borrowingAllowed){
            // TODO: check if user has any borrow limit left and add modifier for blocking borrow operation while current is not finished
            IUAMUserAccount(userAccountManager).requestIndexUpdate{
                flag: MsgFlag.REMAINING_GAS
            }(owner, marketId, knownMarkets, userTip3Wallet, amountToBorrow);
            borrowingAllowed = false;
        } else {
            address(msg.sender).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
        }
    }

    function updateIndexes(uint32 marketId_, mapping(uint32 => fraction) newIndexes, address userTip3Wallet, uint256 toBorrow) external override onlyUserAccountManager {
        for ((uint32 marketId, fraction index): newIndexes) {
            _updateMarketInfo(marketId, index);
        }
        this._calculateTmpBorrowInfo{flag: MsgFlag.REMAINING_GAS}(marketId_, userTip3Wallet, toBorrow);
    }

    function _updateMarketInfo(uint32 marketId, fraction index) internal {
        fraction tmpf;
        for ((, BorrowInfo bi): markets[marketId].borrowInfo) {
            tmpf = index.fNumMul(bi.toRepay);
            tmpf = tmpf.fDiv(bi.index);
            bi.toRepay = tmpf.toNum();
            bi.index = index;
        }
    }

    function _calculateTmpBorrowInfo(uint32 marketId_, address userTip3Wallet, uint256 toBorrow) external view onlySelf {
        mapping(uint32 => uint256) borrowInfo;
        mapping(uint32 => uint256) supplyInfo;
        for ((uint32 marketId, UserMarketInfo umi) : markets) {
            supplyInfo[marketId] = umi.suppliedTokens;
            for ((uint8 borrowId, BorrowInfo bi): umi.borrowInfo) {
                borrowInfo[borrowId] += bi.toRepay;
            }
        }

        IUAMUserAccount(userAccountManager).passBorrowInformation{
            flag: MsgFlag.REMAINING_GAS
        }(owner, userTip3Wallet, marketId_, toBorrow, borrowInfo, supplyInfo);
    }

    function writeBorrowInformation(uint32 marketId_, uint256 toBorrow, address userTip3Wallet, fraction marketIndex) external override onlyUserAccountManager {
        uint8 currentBorrowId = markets[marketId_].borrowInfo.getMaxItem();
        BorrowInfo bi = BorrowInfo(toBorrow, marketIndex);
        markets[marketId_].borrowInfo[currentBorrowId] = bi;

        IUAMUserAccount(userAccountManager).requestTokenPayout{
            flag: MsgFlag.REMAINING_GAS
        }(owner, userTip3Wallet, marketId_, toBorrow);
    }

    /*********************************************************************************************************/
    // repay functions

    function sendRepayInfo(address userTip3Wallet, uint32 marketId, uint8 loanId, uint256 tokensForRepay) external override view onlyUserAccountManager {
        IUAMUserAccount(userAccountManager).sendRepayInfo{
            flag: MsgFlag.REMAINING_GAS
        }(owner, userTip3Wallet, marketId, loanId, tokensForRepay, markets[marketId].borrowInfo[loanId]);
    }

    function writeRepayInformation(address userTip3Wallet, uint32 marketId_, uint8 loanId, uint256 tokensToReturn, BorrowInfo bi) external override onlyUserAccountManager {
        if (bi.toRepay == 0) {
            markets[marketId_].borrowInfo.removeItemFrom(loanId);
        } else {
            markets[marketId_].borrowInfo[loanId] = bi;
        }

        if (tokensToReturn != 0) { 
            IUAMUserAccount(userAccountManager).requestTokenPayout{
                flag: MsgFlag.REMAINING_GAS
            }(owner, userTip3Wallet, marketId_, tokensToReturn);
        } else {
            address(owner).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
        }
    }

    /*********************************************************************************************************/

    // Functon can only be called by the AccountManaget contract
    /**
     * @param marketId_ Id of market to enter
     */
    function enterMarket(uint32 marketId_) external override onlyRoot {
        if (!knownMarkets[marketId_]) {
            knownMarkets[marketId_] = true;

            markets[marketId_] = UserMarketInfo(
                marketId_,
                0
            );
        }
        address(owner).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    /*********************************************************************************************************/
    // Functions for owner

    function withdrawExtraTons() external override view onlyOwner {
        address(owner).transfer({ value: 0, bounce: false, flag: MsgFlag.ALL_NOT_RESERVED });
    }

    /*********************************************************************************************************/
    // modifiers
    modifier onlyRoot() {
        require(msg.sender == root);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyUserAccountManager() {
        require(msg.sender == userAccountManager);
        tvm.rawReserve(msg.value, 2);
        _;
    }

    modifier onlySelf() {
        require(msg.sender == address(this));
        _;
    }

    /**
     * @param contractType_ Type of contract
     */
    modifier correctContractType(uint8 contractType_) {
        require(contractType == contractType_);
        _;
    }
}