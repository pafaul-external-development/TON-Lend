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

    bool public borrowLock;

    address static owner;
    
    // Used for interactions with market 
    address public userAccountManager;

    // Information for update
    uint32 public contractCodeVersion;

    fraction public accountHealth;

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

    // Contract is deployed via platform
    constructor() public { 
        tvm.accept();
        userAccountManager = msg.sender;
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

    function writeSupplyInfo(uint32 marketId, uint256 tokensToSupply, fraction index) external override onlyUserAccountManager {
        tvm.rawReserve(msg.value, 2);
        markets[marketId].suppliedTokens += tokensToSupply;
        _updateMarketInfo(marketId, index);
        this.checkUserAccountHealth{
            flag: MsgFlag.REMAINING_GAS
        }();
    }

    /*********************************************************************************************************/
    // Withdraw functions

    function withdraw(address userTip3Wallet, uint32 marketId, uint256 tokensToWithdraw) external override view onlyOwner {
        require(tokensToWithdraw >= markets[marketId].suppliedTokens);
        tvm.rawReserve(msg.value, 2);
        
        IUAMUserAccount(userAccountManager).requestWithdraw{
            flag: MsgFlag.REMAINING_GAS
        }(owner, userTip3Wallet, marketId, tokensToWithdraw);
    }

    function requestWithdrawInfo(address userTip3Wallet, uint32 marketId, uint256 tokensToWithdraw, mapping(uint32 => fraction) updatedIndexes) external override onlyUserAccountManager {
        tvm.rawReserve(msg.value, 2);
        if (
            accountHealth.nom > accountHealth.denom
        ) {
            for ((uint32 marketId_, fraction index): updatedIndexes) {
                _updateMarketInfo(marketId_, index);
            }

            mapping(uint32 => uint256) borrowInfo;
            mapping(uint32 => uint256) supplyInfo;

            (borrowInfo, supplyInfo) = _calculateBorrowSupplyInfo();

            IUAMUserAccount(userAccountManager).receiveWithdrawInfo{
                flag: MsgFlag.REMAINING_GAS
            }(owner, userTip3Wallet, tokensToWithdraw, marketId, supplyInfo, borrowInfo);
        } else {
            address(owner).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
        }
    }

    function writeWithdrawInfo(address userTip3Wallet, uint32 marketId, uint256 tokensToWithdraw, uint256 tokensToSend) external override onlyUserAccountManager{
        tvm.rawReserve(msg.value, 2);
        markets[marketId].suppliedTokens -= tokensToWithdraw;

        // TODO: add account health check

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
            (accountHealth.nom > accountHealth.denom)
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

    function borrowUpdateIndexes(uint32 marketId, mapping(uint32 => fraction) updatedIndexes, address userTip3Wallet, uint256 toBorrow) external override onlyUserAccountManager {
        tvm.rawReserve(msg.value, 2);

        _updateIndexes(updatedIndexes);

        mapping(uint32 => uint256) borrowInfo;
        mapping(uint32 => uint256) supplyInfo;

        (borrowInfo, supplyInfo) = _calculateBorrowSupplyInfo();

        IUAMUserAccount(userAccountManager).passBorrowInformation{
            flag: MsgFlag.REMAINING_GAS
        }(owner, userTip3Wallet, marketId, toBorrow, borrowInfo, supplyInfo);
    }

    function writeBorrowInformation(uint32 marketId, uint256 toBorrow, address userTip3Wallet, fraction marketIndex) external override onlyUserAccountManager {
        tvm.rawReserve(msg.value, 2);
        if (toBorrow > 0) {
            _updateMarketInfo(marketId, marketIndex);
            markets[marketId].borrowInfo.tokensBorrowed += toBorrow;
        }

        borrowLock = false;

        if (toBorrow > 0) {
            IUAMUserAccount(userAccountManager).requestTokenPayout{
                flag: MsgFlag.REMAINING_GAS
            }(owner, userTip3Wallet, marketId, toBorrow);
        } else {
            this.checkUserAccountHealth{
                flag: MsgFlag.REMAINING_GAS
            }();
        }
    }

    /*********************************************************************************************************/
    // repay functions

    function sendRepayInfo(address userTip3Wallet, uint32 marketId, uint256 tokensForRepay, mapping(uint32 => fraction) updatedIndexes) external override onlyUserAccountManager {
        tvm.rawReserve(msg.value, 2);
        for ((uint32 marketId_, fraction index): updatedIndexes) {
            _updateMarketInfo(marketId_, index);
        }

        IUAMUserAccount(userAccountManager).receiveRepayInfo{
            flag: MsgFlag.REMAINING_GAS
        }(owner, userTip3Wallet, tokensForRepay, marketId, markets[marketId].borrowInfo);
    }

    function writeRepayInformation(address userTip3Wallet, uint32 marketId, uint256 tokensToReturn, BorrowInfo bi) external override onlyUserAccountManager {
        tvm.rawReserve(msg.value, 2);

        markets[marketId].borrowInfo = bi;
        
        if (tokensToReturn != 0) { 
            IUAMUserAccount(userAccountManager).requestTokenPayout{
                flag: MsgFlag.REMAINING_GAS
            }(owner, userTip3Wallet, marketId, tokensToReturn);
        } else {
            this.checkUserAccountHealth{
                flag: MsgFlag.REMAINING_GAS
            }();
        }
    }

    /*********************************************************************************************************/
    // Check account health functions

    function checkUserAccountHealth(address gasTo) external override onlyExecutor {
        tvm.rawReserve(msg.value, 2);
        mapping(uint32 => uint256) supplyInfo;
        mapping(uint32 => BorrowInfo) borrowInfo;
        (borrowInfo, supplyInfo) = _calculateFullBorrowSupplyInfo();
        IUAMUserAccount(userAccountManager).calculateUserAccountHealth{
            flag: MsgFlag.REMAINING_GAS
        }(owner, gasTo, supplyInfo, borrowInfo);
    }

    function updateUserAccountHealth(address gasTo, fraction _accountHealth, mapping(uint32 => fraction) updatedIndexes) external override onlyUserAccountManager {
        accountHealth = _accountHealth;
        _updateIndexes(updatedIndexes);
        address(gasTo).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    /*********************************************************************************************************/
    // Check account health functions

    

    /*********************************************************************************************************/
    // internal functions
    
    function _updateIndexes(mapping(uint32 => fraction) updatedIndexes) internal {
        for ((uint32 marketId_, fraction index): updatedIndexes) {
            _updateMarketInfo(marketId_, index);
        }
    }

    function _updateMarketInfo(uint32 marketId, fraction index) internal {
        fraction tmpf;
        BorrowInfo bi = markets[marketId].borrowInfo;
        if (markets[marketId].borrowInfo.tokensBorrowed != 0) {
            tmpf = bi.tokensBorrowed.numFMul(index);
            tmpf = tmpf.fDiv(bi.index);
        }
        markets[marketId].borrowInfo = BorrowInfo(tmpf.toNum(), index);
    }

    function _calculateBorrowSupplyInfo() internal view returns(mapping(uint32 => uint256) borrowInfo, mapping(uint32 => uint256) supplyInfo) {
        for ((uint32 marketId, UserMarketInfo umi) : markets) {
            supplyInfo[marketId] = umi.suppliedTokens;
            borrowInfo[marketId] = umi.borrowInfo.tokensBorrowed;
        }
    }

    function _calculateFullBorrowSupplyInfo() internal view returns(mapping(uint32 => BorrowInfo) borrowInfo, mapping(uint32 => uint256) supplyInfo) {
        for ((uint32 marketId, UserMarketInfo umi) : markets) {
            supplyInfo[marketId] = umi.suppliedTokens;
            borrowInfo[marketId] = umi.borrowInfo;
        }
    }

    /*********************************************************************************************************/

    // Functon can only be called by the AccountManaget contract
    /**
     * @param marketId Id of market to enter
     */
    function enterMarket(uint32 marketId) external override onlyOwner {
        tvm.rawReserve(msg.value, 2);
        if (!knownMarkets[marketId]) {
            knownMarkets[marketId] = true;

            markets[marketId].exists = true;
            markets[marketId]._marketId = marketId;
            markets[marketId].suppliedTokens = 0;
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
        _;
    }

    modifier onlySelf() {
        require(msg.sender == address(this));
        _;
    }

    modifier onlyExecutor() {
        require(
            msg.sender == userAccountManager ||
            msg.sender == owner ||
            msg.sender == address(this)
        );
        _;
    }
}