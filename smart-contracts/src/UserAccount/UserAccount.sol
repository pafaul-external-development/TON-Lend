pragma ton-solidity >= 0.43.0;
pragma AbiHeader pubkey;
pragma AbiHeader expire;
pragma AbiHeader time;

import "./interfaces/IUserAccount.sol";
import "./libraries/UserAccountErrorCodes.sol";

import "./interfaces/IUAMUserAccount.sol";

import "../utils/interfaces/IUpgradableContract.sol";
import "../utils/libraries/MsgFlag.sol";

contract UserAccount is IUserAccount, IUserAccountData, IUpgradableContract, IUserAccountGetters {
    using UFO for uint256;
    using FPO for fraction;
    using ManageMapping for mapping(uint8 => BorrowInfo);

    bool borrowLock;

    address static owner;
    
    // Used for interactions with market 
    address userAccountManager;

    // Information for update
    uint32 contractCodeVersion;

    mapping(uint32 => bool) knownMarkets;
    mapping(uint32 => UserMarketInfo) markets;

    function getKnownMarkets() external override view responsible returns(mapping(uint32 => bool)) {
        return {flag: MsgFlag.REMAINING_GAS} knownMarkets;
    }

    function getAllMarketsInfo() external override view responsible returns(mapping(uint32 => UserMarketInfo)) {
        return {flag: MsgFlag.REMAINING_GAS} markets;
    }

    function getMarketInfo(uint32 marketId) external override view responsible returns(UserMarketInfo) {
        return {flag: MsgFlag.REMAINING_GAS} markets[marketId];
    }

    function getLoanInfo(uint32 marketId, uint8 loanId) external override view responsible returns(BorrowInfo) {
        return {flag: MsgFlag.REMAINING_GAS} markets[marketId].borrowInfo[loanId];
    }

    // Contract is deployed via platform
    constructor() public { 
        tvm.accept();
    }

    function upgradeContractCode(TvmCell code, TvmCell updateParams, uint32 codeVersion) override external onlyUserAccountManager {
        require(!borrowLock);
        tvm.accept();

        tvm.setcode(code);
        tvm.setCurrentCode(code);

        onCodeUpgrade(
            borrowLock,
            owner,
            userAccountManager,
            knownMarkets,
            markets,
            updateParams,
            codeVersion
        );
    }

    function onCodeUpgrade(
        bool,
        address,
        address,
        mapping(uint32 => bool),
        mapping(uint32 => UserMarketInfo),
        TvmCell,
        uint32
    ) private {

    }

    function getOwner() external override responsible view returns(address) {
        return { value: 0, bounce: false, flag: MsgFlag.REMAINING_GAS } owner;
    }

    /*********************************************************************************************************/
    // Supply functions

    function writeSupplyInfo(address userTip3Wallet, uint32 marketId, uint256 tokensToSupply, fraction index) external override onlyUserAccountManager {
        markets[marketId].suppliedTokens += tokensToSupply;
        _updateMarketInfo(marketId, index);
        IUAMUserAccount(userAccountManager).requestVTokenMint{
            flag: MsgFlag.REMAINING_GAS
        }(owner, userTip3Wallet, marketId, tokensToSupply);
    }

    /*********************************************************************************************************/
    // Withdraw functions

    function requestWithdrawInfo(address userTip3Wallet, address originalTip3Wallet, uint32 marketId, uint256 tokensToWithdraw, mapping(uint32 => fraction) updatedIndexes) external override onlyUserAccountManager {
        for ((uint32 marketId_, fraction index): updatedIndexes) {
            _updateMarketInfo(marketId_, index);
        }

        mapping(uint32 => uint256) borrowInfo;
        mapping(uint32 => uint256) supplyInfo;

        (borrowInfo, supplyInfo) = _calculateBorrowSupplyInfo();

        IUAMUserAccount(userAccountManager).receiveWithdrawInfo{
            flag: MsgFlag.REMAINING_GAS
        }(owner, userTip3Wallet, originalTip3Wallet, tokensToWithdraw, marketId, supplyInfo, borrowInfo);
    }

    function writeWithdrawInfo(address userTip3Wallet, uint32 marketId, uint256 tokensToWithdraw, uint256 tokensToSend) external override onlyUserAccountManager{
        markets[marketId].suppliedTokens -= tokensToWithdraw;

        IUAMUserAccount(userAccountManager).requestTokenPayout{
            flag: MsgFlag.REMAINING_GAS
        }(owner, userTip3Wallet, marketId, tokensToSend);
    }

    /*********************************************************************************************************/
    // Borrow functions

    function borrow(uint32 marketId, uint256 amountToBorrow, address userTip3Wallet) external override onlyOwner {
        tvm.rawReserve(msg.value, 2);
        if (
            (!borrowLock) &&
            (markets[marketId].exists) &&
            (markets[marketId].borrowInfo.getMaxItem() < UserAccountConstants.MAX_BORROWS_PER_MARKET)
        ) {
            borrowLock = true;
            TvmBuilder tb;
            tb.store(owner);
            tb.store(userTip3Wallet);
            tb.store(amountToBorrow);
            IUAMUserAccount(userAccountManager).requestIndexUpdate{
                flag: MsgFlag.REMAINING_GAS
            }(owner, marketId, tb.toCell());
        } else {
            address(msg.sender).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
        }
    }

    function updateIndexes(uint32 marketId, mapping(uint32 => fraction) newIndexes, address userTip3Wallet, uint256 toBorrow) external override onlyUserAccountManager {
        for ((uint32 marketId_, fraction index): newIndexes) {
            _updateMarketInfo(marketId_, index);
        }

        mapping(uint32 => uint256) borrowInfo;
        mapping(uint32 => uint256) supplyInfo;

        (borrowInfo, supplyInfo) = _calculateBorrowSupplyInfo();

        IUAMUserAccount(userAccountManager).passBorrowInformation{
            flag: MsgFlag.REMAINING_GAS
        }(owner, userTip3Wallet, marketId, toBorrow, borrowInfo, supplyInfo);
    }

    function writeBorrowInformation(uint32 marketId, uint256 toBorrow, address userTip3Wallet, fraction marketIndex) external override onlyUserAccountManager {
        if (toBorrow > 0) {
            uint8 currentBorrowId = markets[marketId].borrowInfo.getMaxItem();
            BorrowInfo bi = BorrowInfo(toBorrow, marketIndex);
            markets[marketId].borrowInfo[currentBorrowId] = bi;
        }

        borrowLock = false;

        if (toBorrow > 0) {
            IUAMUserAccount(userAccountManager).requestTokenPayout{
                flag: MsgFlag.REMAINING_GAS
            }(owner, userTip3Wallet, marketId, toBorrow);
        } else {
            owner.transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
        }
    }

    /*********************************************************************************************************/
    // repay functions

    function sendRepayInfo(address userTip3Wallet, uint32 marketId, uint8 loanId, uint256 tokensForRepay, mapping(uint32 => fraction) updatedIndexes) external override onlyUserAccountManager {
        for ((uint32 marketId_, fraction index): updatedIndexes) {
            _updateMarketInfo(marketId_, index);
        }

        IUAMUserAccount(userAccountManager).receiveRepayInfo{
            flag: MsgFlag.REMAINING_GAS
        }(owner, userTip3Wallet, tokensForRepay, marketId, loanId, markets[marketId].borrowInfo[loanId]);
    }

    function writeRepayInformation(address userTip3Wallet, uint32 marketId, uint8 loanId, uint256 tokensToReturn, BorrowInfo bi) external override onlyUserAccountManager {
        if (bi.toRepay == 0) {
            markets[marketId].borrowInfo.removeItemFrom(loanId);
        } else {
            markets[marketId].borrowInfo[loanId] = bi;
        }

        if (tokensToReturn != 0) { 
            IUAMUserAccount(userAccountManager).requestTokenPayout{
                flag: MsgFlag.REMAINING_GAS
            }(owner, userTip3Wallet, marketId, tokensToReturn);
        } else {
            address(owner).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
        }
    }

    /*********************************************************************************************************/
    // internal functions
    function _updateMarketInfo(uint32 marketId, fraction index) internal {
        fraction tmpf;
        for ((, BorrowInfo bi): markets[marketId].borrowInfo) {
            tmpf = index.fNumMul(bi.toRepay);
            tmpf = tmpf.fDiv(bi.index);
            bi.toRepay = tmpf.toNum();
            bi.index = index;
        }
    }

    function _calculateBorrowSupplyInfo() internal view returns(mapping(uint32 => uint256), mapping(uint32 => uint256)) {
        mapping(uint32 => uint256) borrowInfo;
        mapping(uint32 => uint256) supplyInfo;
        for ((uint32 marketId, UserMarketInfo umi) : markets) {
            supplyInfo[marketId] = umi.suppliedTokens;
            for ((uint8 borrowId, BorrowInfo bi): umi.borrowInfo) {
                borrowInfo[borrowId] += bi.toRepay;
            }
        }

        return (borrowInfo, supplyInfo);
    }

    /*********************************************************************************************************/

    // Functon can only be called by the AccountManaget contract
    /**
     * @param marketId Id of market to enter
     */
    function enterMarket(uint32 marketId) external override {
        if (!knownMarkets[marketId]) {
            knownMarkets[marketId] = true;

            markets[marketId] = UserMarketInfo(
                true,
                marketId,
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
}