pragma ton-solidity >= 0.39.0;
pragma AbiHeader pubkey;
pragma AbiHeader expire;
pragma AbiHeader time;

import "./interfaces/IUserAccount.sol";
import "./interfaces/IUserAccountData.sol";
import "./libraries/UserAccountErrorCodes.sol";

import "../utils/interfaces/IUpgradableContract.sol";
import "../utils/libraries/MsgFlag.sol";

import "../../Market/libraries/MarketPayloads.sol";

contract UserAccount is IUserAccount, IUserAccountData, IUpgradableContract {
    using UFO for uint256;
    using FPO for fraction;

    address msigOwner;
    
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
                    address msigOwner
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
        (msigOwner, userAccountManager) = ownerData.decode(address, address);
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
                    address msigOwner
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
        userDataBuilder.store(msigOwner);
        userDataBuilder.store(userAccountManager);

        TvmBuilder userDataMapping;
        userDataMapping.store(userData);
        userDataBuilder.store(userDataMapping.toCell());
        builder.store(userDataBuilder.toCell());

        tvm.setcode(code);
        tvm.setCurrentCode(code);

        onCodeUpgrade(builder.toCell());
    }

    function getOwner() external override responsible view returns(address) {
        return { value: 0, bounce: false, flag: MsgFlag.REMAINING_GAS } msigOwner;
    }



    /*********************************************************************************************************/
    // UserAccountManager interactions

    /**
     * @param payload Payload containing information to write to user's account
     */
    function writeInformationToUserAccount(TvmCell payload) external override onlyUserAccountManager responsible returns(address, TvmCell responce) {
        tvm.rawReserve(msg.value, 2);
        (uint8 operationId, TvmCell args) = MarketToUserPayloads.getOperationType(payload);
        TvmBuilder responceBuilder;

        if (operationId == MarketOperations.SUPPLY_TOKENS) {
            (uint32 marketId, uint256 suppliedTokens, address userSupplyAddress) = MarketToUserPayloads.decodeSupplyOperation(args);
            market[marketId].suppliedTokens += suppliedTokens;
            responceBuilder.store(responceBuilder.RESPONSE_SUPPLY_TOKENS);
            responceBuilder.store(args);
        }
        return {flag: MsgFlag.REMAINING_GAS} (msigOwner, responceBuilder.toCell());
    }

    function borrow(uint32 marketId, uint256 amountToBorrow, address userTIP3) external onlyOwner {
        tvm.rawReserve(msg.value, 2);
        if (borrowAllowed){
            // TODO: check if user has any borrow limit left and add modifier for blocking borrow operation while current is not finished
            IUserAccountManager(userAccountManager).requestIndexUpdate{
                flag: MsgFlag.REMAINING_GAS
            }(owner, marketId, knownMarkets, userTIP3, amountToBorrow);
        } else {
            address(msg.sender).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
        }
    }

    function updateIndexes(uint32 marketId_, mapping(uint32 => fraction) newIndexes, address userTip3Wallet, uint256 toBorrow) external override {
        for ((uint32 marketId, fraction index): newIndexes) {
            _updateMarketInfo(marketId, index);
        }
        this._calculateTmpBorrowInfo{flag: MsgFlag.REMAINING_GAS}(marketId_, userTip3Wallet, toBorrow);
    }

    function _updateMarketInfo(uint32 marketId, fraction index) internal {
        uint256 tmp;
        fraction tmpf;
        for ((uint8 borrowIndex, BorrowInfo bi): markets[marketId].borrowInfo) {
            tmpf = index.fMulNum(bi.toRepay);
            tmpf = tmpf.fDiv(bi.index);
            bi.toRepay = tmpf.toNum();
            bi.index = index;
        }
    }

    function _calculateTmpBorrowInfo(uint32 marketId_, address userTip3Wallet, uint256 toBorrow) external onlySelf {
        tvm.rawReserve(msg.value, 2);
        mapping(uint32 => uint256) borrowInfo;
        mapping(uint32 => uint256) supplyInfo;
        for ((uint32 marketId, UserMarketInfo umi) : markets) {
            supplyInfo[marketId] = umi.supplyInfo
            for ((uint8 borrowId, BorrowInfo bi): umi.borrowInfo) {
                borrowInfo[borrowId] += bi.toRepay;
            }
        }

        UserAccountManager(userAccountManager).requestBorrow{
            flag: MsgFlag.REMAINING_GAS
        }(owner, userTip3Wallet, toBorrow, borrowInfo, supplyInfo);
    }

    function calculateTotalSupply() internal returns (mapping(uint32 => uint256)) {
        mapping (uint32 => uint256) ts;
        for(UserMarketInfo umi: markets) {
            ts[umi.marketId] = umi.suppliedTokens;
        }
        return ts;
    }

    /*********************************************************************************************************/
    // Write information to user account

    function writeSupplyInfo(uint32 marketId_, uint256 tokensToSupply, fraction index) external onlyUserAccountManager {
        tvm.rawReserve(msg.value, 2);
        markets[marketId_].suppliedTokens += tokensToSupply;
        _updateMarketInfo(marketId_, index);
        address(msigOwner).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    function writeBorrowInformation(uint32 marketId_, uint256 toBorrow, address userTIP3, fraction index) external onlyUserAccountManager {
        tvm.rawReserve(msg.value, 2);
        BorrowInfo bi = BorrowInfo({
            toRepay: toBorrow,
            index: index
        });
        uint8 maxIndex = markets[marketId_].borrowInfo.getMaxItem() + 1;
        markets[marketId_][maxIndex] = bi;
        UserAccountManager(userAccountManager).requestTokenPayout{
            flag: MsgFlag.REMAINING_GAS
        }(owner, toBorrow, userTIP3);
    }

    /*********************************************************************************************************/

    // Functon can only be called by the AccauntManaget contract
    /**
     * @param marketId Id of market to enter
     */
    function enterMarket(uint32 marketId) external override onlyRoot {
        tvm.rawReserve(msg.value, 2);
        if (!knownMarkets[marketId]) {
            knownMarkets[marketId] = true;
            BorrowInfo borrowSummary;
            mapping(uint8 => BorrowInfo) borrowInfo;

            markets[marketId] = UserMarketInfo({
                marketId: marketId,
                suppliedTokens: 0,
                borrowSummary: borrowSummary,
                borrowInfo: borrowInfo
            });
        }
        address(msigOwner).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    /*********************************************************************************************************/
    // Functions for owner

    function withdrawExtraTons() external view onlyOwner {
        address(msigOwner).transfer({ value: 0, bounce: false, flag: MsgFlag.ALL_NOT_RESERVED });
    }

    /*********************************************************************************************************/
    // modifiers
    modifier onlyRoot() {
        require(msg.sender == root);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == msigOwner);
        _;
    }

    modifier onlyUserAccountManager() {
        require(msg.sender == userAccountManager);
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