pragma ton-solidity >= 0.39.0;

import "./interfaces/IMarketInteractions.sol"; 
import "./interfaces/IMarketGetters.sol";

import "./libraries/CostConstants.sol";
import "./libraries/MarketErrorCodes.sol";
import "./libraries/MarketOperations.sol";

import "../Controllers/interfaces/ICCMarketDeployed.sol";

import "../TIP3Deployer/interfaces/ITIP3Deployer.sol";

import "../utils/interfaces/IUpgradableContract.sol";

import "../utils/libraries/MsgFlag.sol";

import "../utils/libraries/FloatPointOperations.sol";

contract MarketAggregator is IMarketUAM, IUpgradableContract, IMarketOracle, IMarketSetters, IMarketTIP3Root, IMarketOwnerFunctions, IMarketGetters {
    using UFO for uint256;
    using FPO for fraction;

    // Information for update
    address root;
    uint8 contractType;
    uint32 contractCodeVersion;
    TvmCell platformCode;
    
    // owner info
    address owner;

    address userAccountManager;
    address walletController;
    address oracle;
    address tip3Deployer;
    mapping(uint32 => bool) createdMarkets;
    mapping(address => uint32) tokensToMarkets;
    mapping(uint32 => MarketInfo) markets;
    mapping(address => fraction) tokenPrices;
    mapping(address => bool) realTokenRoots;
    mapping(address => bool) virtualTokenRoots;

    /*********************************************************************************************************/
    // Base functions - for deploying and upgrading contract
    // We are using Platform so constructor is not available
    constructor() public {
        revert();
    }

    /**
     * @param code New contract code
     * @param updateParams Extrenal parameters used during update
     * @param codeVersion_ New code version
     * @param contractType_ Contract type of received update
     */
    function upgradeContractCode(TvmCell code, TvmCell updateParams, uint32 codeVersion_, uint8 contractType_) override external onlyRoot correctContractType(contractType_) {
        tvm.accept();

        TvmBuilder builder;

        tvm.setcode(code);
        tvm.setCurrentCode(code);

        onCodeUpgrade(builder.toCell());
    }
    
    /*
        Data for upgrade from platform to version 0:
        data:
            bits:
                address root
                uint8 contractType
            refs:
                1. platformCode
                2. initialData:
                    refs: 
                    1. Service addresses
                        bits: 
                        1. userAccountManager
                        2. walletController
                        3. oracle
                    2. Owner info:
                        bits:
                        1. ownerAddress
    */
    /**
     * @param data Data builded in upgradeContractCode
     */
    function onCodeUpgrade(TvmCell data) private {
        tvm.resetStorage();
        TvmSlice dataSlice = data.toSlice();
        (root, contractType) = dataSlice.decode(address, uint8);
        contractCodeVersion = 0;

        platformCode = dataSlice.loadRef();         // Loading platform code
        TvmSlice initialData = dataSlice.loadRefAsSlice();
        TvmSlice tmp = initialData.loadRefAsSlice();
        (userAccountManager, walletController, oracle) = tmp.decode(address, address, address);
        tmp = initialData.loadRefAsSlice();
        (owner) = tmp.decode(address);
    }

    /*********************************************************************************************************/
    // Manage markets functions
    /**
     * @param marketId Id of new market that will be created
     * @param realToken Address of real token that will be used in market
     * @param kinkNom ????
     * @param kinkDenom ????
     * @param collNom ????
     * @param collDenom ????
     */
    function createNewMarket(uint32 marketId, address realToken, uint32 kinkNom, uint32 kinkDenom, uint32 collNom, uint32 collDenom) external onlyOwner {
        tvm.rawReserve(msg.value, 2);
        if (!createdMarkets[marketId]) {
            createdMarkets[marketId] = true;

            markets[marketId] = MarketInfo({
                token: realToken,
                virtualToken: address.makeAddrStd(0, 0),
                kinkNominator: kinkNom,
                kinkDenominator: kinkDenom,
                collateralFactorNominator: collNom,
                collateralFactorDenominator: collDenom
            });

            tokensToMarkets[realToken] = marketId;
            realTokenRoots[realToken] = true;

            this.fetchTIP3Information{flag: MsgFlag.REMAINING_GAS}(realToken);
        } else {
            address(msg.sender).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
        }
    }

    /*********************************************************************************************************/
    // functions for interfaction with TIP-3 tokens
    /**
     * @param realToken Address of real token root
     */
    function fetchTIP3Information(address realToken) external override pure onlySelf {
        tvm.accept();
        IRootTokenContract(realToken).getDetails{
            value: CostConstants.FETCH_TIP3_ROOT_INFORMATION,
            bounce: true,
            callback: this.receiveTIP3Information
        }();
    }

    /**
     * @param rootTokenDetails Received information about real token
     */
    function receiveTIP3Information(IRootTokenContract.IRootTokenContractDetails rootTokenDetails) external override view onlyRealTokenRoot {
        tvm.accept();
        TvmBuilder marketIdInfo;
        marketIdInfo.store(tokensToMarkets[msg.sender]);
        prepareDataForNewTIP3(rootTokenDetails, marketIdInfo.toCell());
    }

    /**
     * @param rootTokenDetails Received information about real token
     * @param payloadToReturn Payload that will be received with address of new tip3 root (will contain marketId)
     */
    function prepareDataForNewTIP3(IRootTokenContract.IRootTokenContractDetails rootTokenDetails, TvmCell payloadToReturn) private view {
        tvm.accept();
        IRootTokenContract.IRootTokenContractDetails newRootInfo;
        string initialName = "v";
        initialName.append(string(rootTokenDetails.name));
        newRootInfo.name = bytes(initialName);
        string initialSymbol = "v";
        initialSymbol.append(string(rootTokenDetails.symbol));
        newRootInfo.symbol = bytes(initialSymbol);
        newRootInfo.decimals = rootTokenDetails.decimals;
        newRootInfo.root_public_key = 0;
        newRootInfo.root_owner_address = address(this);
        newRootInfo.total_supply = 0;
        deployNewTIP3Token(newRootInfo, payloadToReturn);
    }

    /**
     * @param newRootTokenDetails Root token information prepared for new token deployment
     * @param payloadToReturn Payload that will be received with address of new tip3 root (will contain marketId)
     */
    function deployNewTIP3Token(IRootTokenContract.IRootTokenContractDetails newRootTokenDetails, TvmCell payloadToReturn) private view {
        tvm.accept();
        ITIP3Deployer(tip3Deployer).deployTIP3{
            value: CostConstants.SEND_TO_TIP3_DEPLOYER,
            bounce: false,
            callback: this.receiveNewTIP3Address
        }(newRootTokenDetails, CostConstants.USE_TO_DEPLOY_TIP3_ROOT, tvm.pubkey(), payloadToReturn);
    }

    /**
     * @param tip3RootAddress Received address of virtual token root
     * @param payload Payload with marketId
     */
    function receiveNewTIP3Address(address tip3RootAddress, TvmCell payload) external override onlyTIP3Deployer {
        tvm.accept();
        TvmSlice s = payload.toSlice();
        uint32 marketId = s.decode(uint32);
        markets[marketId].virtualToken = tip3RootAddress;
        virtualTokenRoots[tip3RootAddress] = true;

        ICCMarketDeployed(root).marketDeployed{
            value: CostConstants.NOTIFY_CONTRACT_CONTROLLER,
            bounce: false
        }(marketId, markets[marketId].token, markets[marketId].virtualToken);
    }

    /*********************************************************************************************************/
    // Interactions with UserAccountManager

    /**
     * @param tonWallet Address of user's ton wallet
     * @param payload Payload with information request
     */
    function fetchInformationFromUserAccount(address tonWallet, TvmCell payload) external override view onlySelf {
        tvm.rawReserve(msg.value, 2);
        IUAMUserAccount(userAccountManager).fetchInformationFromUserAccount{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, payload);
    } 

    /**
     * @param tonWallet Address of user's ton wallet
     * @param payload Payload with result of information request
     */
    function receiveInformationFromUser(address tonWallet, TvmCell payload) external override onlyUserAccountManager {
        tvm.rawReserve(msg.value, 2);
        (uint8 operationId, TvmCell args) = MarketToUserPayloads.getOperationType(payload);

        if (operationId == MarketOperationCodes.RESUME_SUPPLY_TOKENS) {
            this._resumeSupplyExecution{flag: MsgFlag.REMAINING_GAS}(args);
        }

        if (operationId == MarketOperationCodes.BORROW_TOKENS) {
            this._borrowTokens{flag: MsgFlag.REMAINING_GAS}(args);
        }

        if (operationId == MarketOperationCodes.BORROW_FINALIZE_RESPONCE) {
            this._payoutTokens{flag: MsgFlag.REMAINING_GAS}(args);
        }

        if (operationId == MarketOperationCodes.REQUEST_INDEX_UPDATE) {
            this._updateUserIndexes{flag: MsgFlag.REMAINING_GAS}(args);
        }
    }

    function supplyTokensToMarket(address tokenRoot, address msigOwner, address vTokenTIP3, uint128 tokenAmount) external onlyWalletController {
        tvm.rawReserve(msg.value, 2);
        if (realTokenRoots.exists(tokenRoot)) {
            uint256 tokensProvided = uint256(tokenAmount);
            uint32 marketId_ = tokensToMarkets[tokenRoot];
            MarketInfo mi = markets[marketId_];

            fraction exchangeRate = MarketOperations.calculateExchangeRate({
                currentPoolBalance: mi.currentPoolBalance,
                totalBorrowed: mi.totalBorrowed,
                totalReserve: mi.totalReserve,
                totalSupply: mi.totalSupply
            });

            fraction toPayout = tokensProvided.numFDiv(exchangeRate);
            uint256 tokensToProvide = toPayout.toNum();

            mi.suppliedTokens += tokensToSupply;
            mi.currentPoolBalance += tokensToSupply;
            markets[marketId_] = mi;
            _updateMarketState(marketId_);
            IUserAccountManager(userAccountManager).writeSupplyInfo(msigOwner, marketId_, tokensToSupply);
        }
    }

    function requestIndexUpdate(address tonWallet, uint32 marketId, mapping (uint32=>bool) upd, address tip3UserWallet, uint256 amountToBorrow) external onlySelf {
        tvm.rawReserve(msg.value, 2);
        mapping(uint32 => fraction) ui;
        for ((uint32 marketId, bool): upd) {
            ui[marketId] = markets[marketId].index;
        }
        UserAccountManager(userAccountManager).updateUserIndex{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, marketId, ui, tip3UserWallet, amountToBorrow);
    }

    function receiveBorrowInformation(address tonWallet, uint32 marketId_, address userTIP3, uint256 toBorrow, mapping(uint32 => uint256) bi, mapping(uint32 => uint256) si) external onlyUserAccountManager {
        tvm.rawReserve(msg.value, 2);
        uint256 supplySum = 0;
        uint256 borrowSum = 0;
        fraction tmp;
        for ((uint32 marketId, uint256 s): si) {
            tmp = tokenPrices[markets[marketId].realTokenRoot];
            tmp = tmp.fMulNum(s);
            tmp = tmp.fMul(markets[marketId].collateral);
            supplySum += tmp.toNum();
        }

        for ((uint32 marketId, uint256 b): bi) {
            tmp = tokenPrices[markets[marketId].realTokenRoot];
            tmp = tmp.fMulNum(b);
            borrowSum += tmp.toNum();
        }
        if (borrowSum < supplySum) {
            uint256 tmp_ = supplySum - borrowSum;
            tmp = tokenPrices[markets[marketId_].realTokenRoot];
            tmp = tmp_.numFDiv(tmp);
            tmp_ = tmp.toNum();
            if (tmp_ >= toBorrow) {
                markets[marketId_].totalBorrowed += toBorrow;
                markets[marketId_].currentPoolBalance -= toBorrow;
                _updateMarketState(marketId_);
                UserAccountManager(userAccountManager).writeBorrowInformation{
                    flag: MsgFlag.REMAINING_GAS
                }(tonWallet, marketId_, toBorrow, userTIP3, markets[marketId_].index);
            } else {
                address(tonWallet).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
            }
        } else {
            // TODO: mark for liquidation ???
            address(tonWallet).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
        }
    }

    function requestTokenPayout(address tonWallet, uint32 marketId, uint256 toPayout, address userTIP3) external onlyUserAccountManager {
        tvm.rawReserve(msg.value, 2);
        // TODO: payout tokens to users
        address tokenRoot = realTokens[marketId];
        WalletController(walletController).transferTokensTo{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, tokenRoot, toPayout, userTIP3);
    }

    function receiveRepayInformation(address tonWallet, address userTip3Wallet, uint32 marketId_, uint256 tokensForRepay, BorrowInfo bi) external onlySelf {
        tvm.rawReserve(msg.value, 2);
        fraction newRepayInfo = markets[marketId_].index.fMulNum(bi.toRepay);
        newRepayInfo = newRepayInfo.fDiv(bi.index);
        uint256 tokensToRepay = newRepayInfo.toNum();
        uint256 tokensToReturn;
        if (tokensToRepay <= tokensForRepay) {
            tokensToReturn = tokensForRepay - tokensToRepay;
            bi.toRepay = 0;
        } else {
            tokensToReturn = 0;
            bi.toRepay = tokensToRepay - tokensForRepay;
        }

        UserAccountManager(userAccountManager).writeRepayInformation{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, marketId_, userTip3Wallet, tokensToReturn, bi);
    }

    function _payoutTokens(args) external onlySelf {
        tvm.rawReserve(msg.value, 2);
        // TODO: transfer tokens to the address destination
    }

    function repayBorrow(address tokenRoot, address msigOwner, uint128 tokenAmount, uint8 loanId) external onlyWalletController {
        tvm.rawReserve(msg.value, 2);
        if (realTokenRoot.exists(tokenRoot)) {
            uint32 marketId_ = tokensToMarkets[tokenRoot];
            uint256 tokensToPayout = uint256(tokenAmount);
            IUserAccountManager(userAccountManager).requestRepayInfo{
                flag: MsgFlag.REMAINING_GAS
            }(msigOwner, marketId_, loanId, tokensToPayout);
        }
    }

    function _updateMarketState(marketId_) internal {
        MarketInfo mi = markets[marketId_];
        uint256 dt = uint256(now) - mi.lastUpdateTime;
        fraction u = MarketOperations.calculateU(mi.totalBorrowed, mi.currentPoolBalance);
        fraction r = MarketOperations.calculateR(u, mi.baseRate, mi.mul, mi.kink, mi.jumpMul);
        fraction totalBorrowed = MarketOperations.calculateTotalBorrowed(mi.totalBorrowed, r, dt);
        fraction totalReserve = MarketOperations.calculateTotalReserve(mi.totalReserve, mi.totalBorrowed, mi.reserveFactor, r, dt);
        fraction index = MarketOperations.calculateIndex(mi.index, r, dt);
        mi.totalBorrowed = totalBorrowed.toNum();
        mi.totalReserve = totalReserve.toNum();
        mi.index = index.toNum();
        markets[marketId_] = mi;
    }

    /*********************************************************************************************************/
    // Interactions with oracle

    /**
     * @param tokenRoot Address of TIP-3 token root to update
     * @param payload Payload that will be passed during update and received after
     */
    function updatePrice(address tokenRoot, TvmCell payload) internal view {
        IOracleReturnPrices(oracle).getTokenPrice{
            flag: 64,
            callback: this.receiveUpdatedPrice
        }(tokenRoot, payload);
    }

    /**
     * @param tokenRoot Address of updated TIP-3 token root
     * @param nom Nominator of token's price to usd
     * @param denom Denominator of token's price to usd
     * @param payload Received payload (passed in updatePrice)
     */
    function receiveUpdatedPrice(address tokenRoot, uint128 nom, uint128 denom, TvmCell payload) external override onlyOracle {
        tvm.rawReserve(msg.value, 2);
        tokenPrices[tokenRoot] = fraction(nom, denom);
    }

    /**
     * @param payload Payload that will be passed during update and received after
     */
    function updateAllPrices(TvmCell payload) internal view {
        IOracleReturnPrices(oracle).getAllTokenPrices{
            flag: 64,
            callback: this.receiveAllUpdatedPrices
        }(payload);
    }

    /**
     * @param updatedPrices Updated prices of all tokens that exist in oracle
     * @param payload Received payload (passed in updatePrice)
     */
    function receiveAllUpdatedPrices(mapping(address => MarketPriceInfo) updatedPrices, TvmCell payload) external override onlyOracle {
        tvm.rawReserve(msg.value, 2);
        for((address t, MarketPriceInfo mpi): updatedPrices) {
            tokenPrices[t] = fraction(mpi.tokens, mpi.uds);
        }
    }

    /**
     * @notice Anyone can call this funtion
     * @param tokenRoot Address of token that will be updated
     */
    function forceUpdatePrice(address tokenRoot) external override {
        tvm.rawReserve(msg.value, 2);
        TvmCell payload;
        updatePrice(tokenRoot, payload);
    }

    /**
     * @notice Anyone can call this function
     */
    function forceUpdateAllPrices() external override {
        tvm.rawReserve(msg.value, 2);
        TvmCell payload;
        updateAllPrices(payload);
    }

    /*********************************************************************************************************/
    // Internal market story

    function _updateMarketParameters(uint32 marketId) internal {}

    /*********************************************************************************************************/
    // Setters
    /**
     * @param userAccountManager_ Address of userAccountManager smart contract
     */
    function setUserAccountManager(address userAccountManager_) external override onlyOwner {
        tvm.rawReserve(msg.value, 2);
        userAccountManager = userAccountManager_;
        address(msg.sender).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    /**
     * @param tip3WalletController_ Address of TIP3WalletController smart contract
     */
    function setTip3WalletController(address tip3WalletController_) external override onlyOwner {
        tvm.rawReserve(msg.value, 2);
        walletController = tip3WalletController_;
        address(msg.sender).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    /**
     * @param oracle_ Address of Oracle smart contract
     */
    function setOracleAddress(address oracle_) external override onlyOwner {
        tvm.rawReserve(msg.value, 2);
        oracle = oracle_;
        address(msg.sender).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    /**
     * @param newOwner Address of new contract's owner
     */
    function transferOwnership(address newOwner) external override onlyOwner {
        tvm.rawReserve(msg.value, 2);
        owner = newOwner;
        address(msg.sender).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    /*********************************************************************************************************/
    // Getters
    function getServiceContractAddresses() external override view responsible returns(address userAccountManager_, address tip3WalletController_, address oracle_) {
        return {flag: MsgFlag.REMAINING_GAS} (userAccountManager, walletController, oracle);
    }

    function getMarketInformation(uint32 marketId) external override view responsible returns(MarketInfo) {
        return {flag: MsgFlag.REMAINING_GAS} markets[marketId];
    }

    function getAllMarkets() external override view responsible returns(mapping(uint32 => MarketInfo)) {
        return {flag: MsgFlag.REMAINING_GAS} markets;
    }

    function withdrawExtraTons(uint128 amount) external override onlyOwner {
        tvm.accept();
        address(owner).transfer({flag: 1, value: amount});
    }

    /*********************************************************************************************************/
    // Modificators
    // TODO: Add error codes
    modifier onlySelf() {
        require(msg.sender == address(this), MarketErrorCodes.ERROR_MSG_SENDER_IS_NOT_SELF);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == root, MarketErrorCodes.ERROR_MSG_SENDER_IS_NOT_OWNER);
        _;
    }

    modifier onlyRoot() {
        require(msg.sender == root, MarketErrorCodes.ERROR_MSG_SENDER_IS_NOT_ROOT);
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracle, MarketErrorCodes.ERROR_MSG_SENDER_IS_NOT_ORACLE);
        _;
    }

    modifier onlyTIP3Deployer() {
        require(msg.sender == tip3Deployer, MarketErrorCodes.ERROR_MSG_SENDER_IS_NOT_TIP3_DEPLOYER);
        _;
    }

    modifier onlyUserAccountManager() {
        require(msg.sender == userAccountManager, MarketErrorCodes.ERROR_MSG_SENDER_IS_NOT_USER_ACCOUNT_MANAGER);
        _;
    }

    modifier onlyWalletController() {
        require(msg.sender == walletController, MarketErrorCodes.ERROR_MSG_SENDER_IS_NOT_TIP3_WALLET_CONTROLLER);
        _;
    }

    modifier onlyRealTokenRoot() {
        require(realTokenRoots.exists(msg.sender), MarketErrorCodes.ERROR_MSG_SENDER_IS_NOT_REAL_TOKEN);
        _;
    }

    modifier onlyVirtualTokenRoot() {
        require(virtualTokenRoots.exists(msg.sender), MarketErrorCodes.ERROR_MSG_SENDER_IS_NOT_VIRTUAL_TOKEN);
        _;
    }

    /**
     * @param contractType_ Type of contract
     */
    modifier correctContractType(uint8 contractType_) {
        require(contractType == contractType_, MarketErrorCodes.ERROR_INVALID_CONTRACT_TYPE);
        _;
    }
}