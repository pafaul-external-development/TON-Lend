pragma ton-solidity >= 0.39.0;

import "./interfaces/IMarketInterfaces.sol";

import "./libraries/CostConstants.sol";
import "./libraries/MarketErrorCodes.sol";
import "./libraries/MarketOperations.sol";

import "../Controllers/interfaces/ICCMarketDeployed.sol";

import "../TIP3Deployer/interfaces/ITIP3Deployer.sol";

import "../WalletController/interfaces/IWalletControllerMarketInteractions.sol";

import "../utils/interfaces/IUpgradableContract.sol";

import "../utils/libraries/MsgFlag.sol";

import "../utils/libraries/FloatingPointOperations.sol";

contract MarketAggregator is IUpgradableContract, IMarketOracle, IMarketSetters, IMarketTIP3Root, IMarketOwnerFunctions, IMarketGetters, IMarketOperations {
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

    mapping(uint8 => address) modules;

    /*********************************************************************************************************/
    // Cache update functions

    function receiveMarketDelta(address sendGasTo, MarketDelta marketDelta, uint32 marketId) external onlyModules {
        tvm.rawReserve(msg.value, 2);
        if (
            marketDelta.currentPoolBalance.positive &&
            marketDelta.currentPoolBalance.delta != 0
        ) {
            markets[marketId].currentPoolBalance += marketDelta.currentPoolBalance.delta;
        } else {
            markets[marketId].currentPoolBalance -= marketDelta.currentPoolBalance.delta;
        }

        if (
            marketDelta.totalBorrowed.positive &&
            marketDelta.totalBorrowed.delta != 0
        ) {
            markets[marketId].totalBorrowed += marketDelta.totalBorrowed.delta;
        } else {
            markets[marketId].totalBorrowed -= marketDelta.totalBorrowed.delta;
        }

        if (
            marketDelta.totalReserve.positive &&
            marketDelta.totalReserve.delta != 0
        ) {
            markets[marketId].totalReserve += marketDelta.totalReserve.delta;
        } else {
            markets[marketId].totalReserve -= marketDelta.totalReserve.delta;
        }

        if (
            marketDelta.totalSupply.positive &&
            marketDelta.totalSupply.delta != 0
        ) {
            markets[marketId].totalSupply += marketDelta.totalSupply.delta;
        } else {
            markets[marketId].totalSupply -= marketDelta.totalSupply.delta;
        }

        _updateMarketState(marketId);

        uint128 valueToTransfer = msg.value / (modules.length + 1);
        for ((address module) : modules) {
            IMarketStateCache(module).updateCache{
                value: valueToTransfer
            }(sendGasTo, markets, tokenPrices);
        }
    }

    /*********************************************************************************************************/
    // Getters
    function getServiceContractAddresses() external override view responsible returns(address userAccountManager_, address tip3WalletController_, address oracle_) {
        return {flag: MsgFlag.REMAINING_GAS} (userAccountManager, walletController, oracle);
    }

    function getTokenPrices() external override view responsible returns(mapping(address => fraction)) {
        return {flag: MsgFlag.REMAINING_GAS} tokenPrices;
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
    // Events

    event MarketCreated(uint32 marketId, MarketInfo marketState);
    event MarketDeleted(uint32 marketId, MarketInfo marketState);
    event TokensSupplied(address tonWallet, uint32 marketId, uint256 tokensSupplied, MarketInfo marketState);
    event TokensWithdrawn(address tonWallet, uint32 marketId, uint256 tokensWithdrawn, MarketInfo marketState);
    event TokensBorrowed(address tonWallet, uint32 marketId, uint256 tokensBorrowed, MarketInfo marketState);
    event TokensRepayed(address tonWallet, uint32 marketId, uint256 tokensToRepay, uint256 tokensRepayed, MarketInfo marketState);

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
     * @param initialBalance ????
     * @param reserveFactor_ ????
     * @param kink_ ????
     * @param collateral_ ????
     * @param baseRate_ ????
     * @param mul_ ????
     * @param jumpMul_ ????
     */
    function createNewMarket(
        uint32 marketId, 
        address realToken, 
        uint256 initialBalance, 
        fraction reserveFactor_, 
        fraction kink_, 
        fraction collateral_, 
        fraction baseRate_,
        fraction mul_,
        fraction jumpMul_
    ) external onlyOwner {
        tvm.rawReserve(msg.value, 2);
        if (!createdMarkets[marketId]) {
            createdMarkets[marketId] = true;
            
            fraction zero = fraction(0, 1);

            markets[marketId] = MarketInfo({
                token: realToken,
                virtualToken: address.makeAddrStd(0, 0),
                currentPoolBalance: initialBalance,
                totalBorrowed: 0,
                totalReserve: 0,
                totalSupply: 0,

                index: zero,
                reserveFactor: reserveFactor_,
                kink: kink_,
                collateral: collateral_,
                baseRate: baseRate_,
                mul: mul_,
                jumpMul: jumpMul_,

                lastUpdateTime: now
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
        emit MarketCreated(marketId, markets[marketId]);

        ICCMarketDeployed(root).marketDeployed{
            value: CostConstants.NOTIFY_CONTRACT_CONTROLLER,
            bounce: false
        }(marketId, markets[marketId].token, markets[marketId].virtualToken);
    }

    /*********************************************************************************************************/
    // Operations with modules

    function addModule(uint8 operationId, address module) external onlyOwner {
        modules[operationId] = module;
    }

    function performOperationWalletController(uint8 operationId, address tokenRoot, TvmCell args) external view onlyWalletController {
        uint32 marketId = tokensToMarket[tokenRoot];
        address module = modules[operationId];
        IModule(module).performOperation{
            flag: MsgFlag.REMAINING_GAS
        }(marketId, args);
    }

    function performOperationUserAccountManager(uint8 operationId, uint32 marketId, TvmCell args) external view onlyUserAccountManager {
        address module = modules[operationId];
        IModule(module).performOperation{
            flag: MsgFlag.REMAINING_GAS
        }(marketId, args);
    }


    /*********************************************************************************************************/
    // Supply operation part
    // Starts at wallet controller

    function mintVTokens(address tonWallet, address userTip3Wallet, uint32 marketId, uint256 toMint) external view override onlyUserAccountManager {
        tvm.rawReserve(msg.value, 2);

        emit TokensSupplied(tonWallet, marketId, toMint, markets[marketId]);

        IRootTokenContract(markets[marketId].virtualToken).mint{
            flag: MsgFlag.REMAINING_GAS
        }(uint128(toMint), userTip3Wallet);
    }

    /*********************************************************************************************************/
    // Withdraw vTokens part
    // Starts at WalletController

    function withdrawVToken(address tokenRoot, address tonWallet, address userTip3Wallet, address originalTip3Wallet, uint128 tokenAmount) external override onlyWalletController {
        uint32 marketId_ = tokensToMarkets[tokenRoot];
        IUAMUserAccount(userAccountManager).requestWithdrawInfo{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, userTip3Wallet, originalTip3Wallet, marketId_, uint256(tokenAmount));
    }

    function transferVTokensBack(address tonWallet, address userTip3Wallet, uint32 marketId, uint256 tokensToReturn) external override view onlyUserAccountManager {
        IWCMInteractions(walletController).transferTokensToWallet{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, markets[marketId].virtualToken, userTip3Wallet, tokensToReturn);
    }

    /*********************************************************************************************************/
    // Borrow operation part
    // Starts at UserAccount

    function requestIndexUpdate(address tonWallet, uint32 marketId, mapping (uint32=>bool) upd, address tip3UserWallet, uint256 amountToBorrow) external view override onlyUserAccountManager {
        mapping(uint32 => fraction) ui;
        for ((uint32 marketId_, ): upd) {
            ui[marketId_] = markets[marketId_].index;
        }
        IUAMUserAccount(userAccountManager).updateUserIndex{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, marketId, ui, tip3UserWallet, amountToBorrow);
    }

    function _calculateBorrowSupplyDiff(mapping(uint32 => uint256) si, mapping(uint32 => uint256) bi) internal returns (uint256, uint256) {
        uint256 supplySum = 0;
        uint256 borrowSum = 0;
        address marketTokenRoot;
        fraction tmp;

        for ((uint32 marketId, uint256 s): si) {
            marketTokenRoot = markets[marketId].token;
            tmp = tokenPrices[marketTokenRoot];
            tmp = tmp.fNumMul(s);
            tmp = tmp.fMul(markets[marketId].collateral);
            supplySum += tmp.toNum();
        }

        for ((uint32 marketId, uint256 b): bi) {
            marketTokenRoot = markets[marketId].token;
            tmp = tokenPrices[marketTokenRoot];
            tmp = tmp.fNumMul(b);
            borrowSum += tmp.toNum();
        }

        return (supplySum, borrowSum);
    }

    /*********************************************************************************************************/
    // Repay operation part
    // Starts at wallet controller


    /*********************************************************************************************************/
    // Service operations

    function requestTokenPayout(address tonWallet, address userTip3Wallet, uint32 marketId, uint256 toPayout) external view override onlyUserAccountManager {
        address tokenRoot = markets[marketId].token;
        IWCMInteractions(walletController).transferTokensToWallet{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, tokenRoot, userTip3Wallet, toPayout);
    }

    function _updateMarketState(uint32 marketId_) internal {
        MarketInfo mi = markets[marketId_];
        uint256 dt = uint256(now) - mi.lastUpdateTime;
        fraction u = MarketOperations.calculateU(mi.totalBorrowed, mi.currentPoolBalance);
        fraction r = MarketOperations.calculateR(u, mi.baseRate, mi.mul, mi.kink, mi.jumpMul);
        fraction totalBorrowed = MarketOperations.calculateTotalBorrowed(mi.totalBorrowed, r, dt);
        fraction totalReserve = MarketOperations.calculateTotalReserve(mi.totalReserve, mi.totalBorrowed, mi.reserveFactor, r, dt);
        fraction index = MarketOperations.calculateIndex(mi.index, r, dt);
        mi.totalBorrowed = totalBorrowed.toNum();
        mi.totalReserve = totalReserve.toNum();
        mi.index = index;
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
     */
    function receiveUpdatedPrice(address tokenRoot, uint128 nom, uint128 denom, TvmCell) external override onlyOracle {
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
     */
    function receiveAllUpdatedPrices(mapping(address => MarketPriceInfo) updatedPrices, TvmCell) external override onlyOracle {
        for((address t, MarketPriceInfo mpi): updatedPrices) {
            tokenPrices[t] = fraction(mpi.tokens, mpi.usd);
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
    // Setters
    /**
     * @param userAccountManager_ Address of userAccountManager smart contract
     */
    function setUserAccountManager(address userAccountManager_) external override onlyOwner {
        userAccountManager = userAccountManager_;
        address(msg.sender).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    /**
     * @param tip3WalletController_ Address of TIP3WalletController smart contract
     */
    function setTip3WalletController(address tip3WalletController_) external override onlyOwner {
        walletController = tip3WalletController_;
        address(msg.sender).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    /**
     * @param oracle_ Address of Oracle smart contract
     */
    function setOracleAddress(address oracle_) external override onlyOwner {
        oracle = oracle_;
        address(msg.sender).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    /**
     * @param newOwner Address of new contract's owner
     */
    function transferOwnership(address newOwner) external override onlyOwner {
        owner = newOwner;
        address(msg.sender).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    /*********************************************************************************************************/
    // Modificators

    modifier onlySelf() {
        require(msg.sender == address(this), MarketErrorCodes.ERROR_MSG_SENDER_IS_NOT_SELF);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == root, MarketErrorCodes.ERROR_MSG_SENDER_IS_NOT_OWNER);
        tvm.rawReserve(msg.value, 2);
        _;
    }

    modifier onlyRoot() {
        require(msg.sender == root, MarketErrorCodes.ERROR_MSG_SENDER_IS_NOT_ROOT);
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracle, MarketErrorCodes.ERROR_MSG_SENDER_IS_NOT_ORACLE);
        tvm.rawReserve(msg.value, 2);
        _;
    }

    modifier onlyTIP3Deployer() {
        require(msg.sender == tip3Deployer, MarketErrorCodes.ERROR_MSG_SENDER_IS_NOT_TIP3_DEPLOYER);
        _;
    }

    modifier onlyUserAccountManager() {
        require(msg.sender == userAccountManager, MarketErrorCodes.ERROR_MSG_SENDER_IS_NOT_USER_ACCOUNT_MANAGER);
        tvm.rawReserve(msg.value, 2);
        _;
    }

    modifier onlyWalletController() {
        require(msg.sender == walletController, MarketErrorCodes.ERROR_MSG_SENDER_IS_NOT_TIP3_WALLET_CONTROLLER);
        tvm.rawReserve(msg.value, 2);
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