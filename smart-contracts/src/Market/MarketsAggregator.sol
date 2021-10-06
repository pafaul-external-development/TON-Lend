pragma ton-solidity >= 0.43.0;
pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import './interfaces/IMarketInterfaces.sol';

contract MarketAggregator is IUpgradableContract, IMarketOracle, IMarketSetters, IMarketTIP3Root, IMarketOwnerFunctions, IMarketGetters, IMarketOperations, IContractStateCacheRoot {
    using UFO for uint256;
    using FPO for fraction;

    // Information for update
    uint32 public contractCodeVersion;
    
    // owner info
    address owner;

    address public userAccountManager;
    address public walletController;
    address public oracle;
    address public tip3Deployer;
    mapping(uint32 => bool) createdMarkets;
    mapping(address => uint32) tokensToMarkets;
    mapping(uint32 => MarketInfo) markets;
    mapping(address => fraction) tokenPrices;
    mapping(address => bool) realTokenRoots;
    mapping(address => bool) virtualTokenRoots;

    mapping(uint8 => address) public modules;
    uint128 moduleAmount;
    mapping(address => bool) isModule;

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
    constructor(address _owner) public {
        tvm.accept();
        owner = _owner;
    }

    function upgradeContractCode(TvmCell code, TvmCell updateParams, uint32 codeVersion) override external onlyOwner {
        tvm.accept();

        tvm.setcode(code);
        tvm.setCurrentCode(code);

        onCodeUpgrade(
            owner,
            userAccountManager,
            walletController,
            oracle,
            tip3Deployer,
            markets,
            tokenPrices,
            modules,
            updateParams,
            codeVersion
        );
    }

    // mappings like createdMarkets, tokensToMarkets are derivatives from markets mapping and must be recreated
    function onCodeUpgrade(
        address,
        address,
        address,
        address,
        address,
        mapping(uint32 => MarketInfo),
        mapping(address => fraction),
        mapping(uint8 => address),
        TvmCell,
        uint32
    ) private {

    }

    /*********************************************************************************************************/
    // Cache update functions

    function receiveCacheDelta(address sendGasTo, MarketDelta marketDelta, uint32 marketId) external override onlyModule {
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

        uint128 valueToTransfer = msg.value / (moduleAmount + 1);
        for ((, address module) : modules) {
            IContractStateCache(module).updateCache{
                value: valueToTransfer
            }(sendGasTo, markets, tokenPrices);
        }
    }

    function updateModulesCache() external onlyOwner {
        tvm.accept();
        uint128 valueToTransfer = msg.value / (moduleAmount + 1);
        for ((, address module) : modules) {
            IContractStateCache(module).updateCache{
                value: valueToTransfer
            }(owner, markets, tokenPrices);
        }
    }

    /*********************************************************************************************************/
    // Getters
    function getServiceContractAddresses() external override view responsible returns(address _userAccountManager, address _tip3WalletController, address _oracle) {
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

    function getAllModules() external override view responsible returns(mapping(uint8 => address)) {
        return {flag: MsgFlag.REMAINING_GAS} modules;
    }

    /*********************************************************************************************************/
    // Manage markets functions
    function createNewMarket(
        uint32 marketId, 
        address realToken, 
        uint256 initialBalance,
        fraction _baseRate,
        fraction _utilizationMultiplier,
        fraction _reserveFactor,
        fraction _exchangeRate,
        fraction _collateralFactor
    ) external onlyOwner {
        tvm.rawReserve(msg.value, 2);
        if (!createdMarkets[marketId]) {
            createdMarkets[marketId] = true;
            
            fraction one = fraction({nom: 1, denom: 1});

            markets[marketId] = MarketInfo({
                token: realToken,
                realTokenBalance: initialBalance,
                vTokenBalance: 0,
                totalBorrowed: 0,
                totalReserve: 0,

                index: one,
                baseRate: _baseRate,
                utilizationMultiplier: _utilizationMultiplier,
                reserveFactor: _reserveFactor,
                exchangeRate: _exchangeRate,
                collateralFactor: _collateralFactor,

                lastUpdateTime: now
            });

            tokensToMarkets[realToken] = marketId;
        } else {
            address(msg.sender).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
        }
    }

    function updateMarketParameters(
        uint32 marketId,
        fraction _baseRate,
        fraction _utilizationMultiplier,
        fraction _reserveFactor,
        fraction _exchangeRate
    ) external onlyOwner {
        tvm.tvmrawReserve(msg.value, 2);

        MarketInfo mi = markets[marketId];
        mi.baseRate = _baseRate;
        mi.utilizationMultiplier = _utilizationMultiplier;
        mi._reserveFactor = _reserveFactor;
        if (mi.vTokenBalance == 0) {
            mi.exchangeRate = _exchangeRate;
        }

        markets[marketId] = mi;

        _updateMarketState(marketId);

        address(owner).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    /*********************************************************************************************************/
    // Operations with modules

    function addModule(uint8 operationId, address module) external onlyOwner {
        tvm.rawReserve(msg.value, 2);
        modules[operationId] = module;
        isModule[module] = true;
        IContractStateCache(module).updateCache{
            flag: MsgFlag.REMAINING_GAS
        }(owner, markets, tokenPrices);
    }

    function removeModule(uint8 operationId) external onlyOwner {
        tvm.rawReserve(msg.value, 2);
        delete isModule[modules[operationId]];
        delete modules[operationId];

        address(owner).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    function performOperationWalletController(uint8 operationId, address tokenRoot, TvmCell args) external override view onlyWalletController {
        uint32 marketId = tokensToMarkets[tokenRoot];
        address module = modules[operationId];

        // TODO: update price info and then perform operation
        IModule(module).performAction{
            flag: MsgFlag.REMAINING_GAS
        }(marketId, args);
    }

    function performOperationUserAccountManager(uint8 operationId, uint32 marketId, TvmCell args) external override view onlyUserAccountManager {
        address module = modules[operationId];
        // TODO: update price info and then perform operation
        IModule(module).performAction{
            flag: MsgFlag.REMAINING_GAS
        }(marketId, args);
    }

    function performOperation(TvmCell args) internal {
        TvmSlice ts = args.toSlice();

        uint8 operationId = ts.decode(uint8);
        if (operationId != OperationCodes.NO_OP) {
            uint32 marketId = ts.decode(uint32);
            TvmCell moduleArgs = ts.loadRef();
            IModule(modules[operationId]).performAction{
                flag: MsgFlag.REMAINING_GAS
            }(marketId, moduleArgs);
        } else {
            address(owner).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
        }
    }

    function _updateMarketState(uint32 marketId) internal {
        MarketInfo mi = markets[marketId];
        uint256 dt = uint256(now) - mi.lastUpdateTime;
        if (mi.vTokenBalance > 0) {
            mi.exchangeRate = MarketOperations.calculateExchangeRate(mi.realTokenBalance, mi.totalBorrowed, mi.totalReserve, mi.vTokenBalance);
        }
        fraction u = MarketOperations.calculateU(mi.totalBorrowed, mi.realTokenBalance);
        fraction bir = MarketOperations.calculateBorrowInterestRate(mi.baseRate, u, mi.utilizationMul);
        mi.index = MarketOperations.calculateNewIndex(mi.index, bir, dt);
        mi.totalBorrowed = MarketOperations.calculateTotalBorrowed(mi.totalBorrowed, bir, dt);
        mi.totalReserve = MarketOperations.calculateReserves(mi.totalReserve, mi.totalBorrowed, bir, mi.reserveFactor, dt);
        mi.lastUpdateTime = now;
        markets[marketId] = mi;
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
    function receiveUpdatedPrice(address tokenRoot, uint128 nom, uint128 denom, TvmCell payload) external override onlyOracle {
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
    function receiveAllUpdatedPrices(mapping(address => MarketPriceInfo) updatedPrices, TvmCell payload) external override onlyOracle {
        for((address t, MarketPriceInfo mpi): updatedPrices) {
            tokenPrices[t] = fraction(mpi.tokens, mpi.usd);
        }
    }

    /**
     * @notice Owner can use this function to force update all prices
     */
    function forceUpdateAllPrices() external override onlyOwner {
        tvm.rawReserve(msg.value, 2);
        TvmBuilder tb;
        tb.store(OperationCodes.NO_OP);
        updateAllPrices(tb.toCell());
    }

    /*********************************************************************************************************/
    // Setters
    /**
     * @param _userAccountManager Address of userAccountManager smart contract
     */
    function setUserAccountManager(address _userAccountManager) external override onlyOwner {
        tvm.rawReserve(msg.value, 2);
        userAccountManager = _userAccountManager;
        address(msg.sender).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    /**
     * @param _tip3WalletController Address of TIP3WalletController smart contract
     */
    function setWalletController(address _tip3WalletController) external override onlyOwner {
        tvm.rawReserve(msg.value, 2);
        walletController = _tip3WalletController;
        address(msg.sender).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    /**
     * @param _oracle Address of Oracle smart contract
     */
    function setOracleAddress(address _oracle) external override onlyOwner {
        tvm.rawReserve(msg.value, 2);
        oracle = _oracle;
        address(msg.sender).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    function setTip3Deployer(address _tip3Deployer) external override onlyOwner {
        tvm.rawReserve(msg.value, 2);
        tip3Deployer = _tip3Deployer;
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
    // Modificators

    modifier onlySelf() {
        require(msg.sender == address(this), MarketErrorCodes.ERROR_MSG_SENDER_IS_NOT_SELF);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, MarketErrorCodes.ERROR_MSG_SENDER_IS_NOT_OWNER);
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

    modifier onlyRealTokenRoot() {
        require(realTokenRoots.exists(msg.sender));
        _;
    }

    modifier onlyModule() {
        require(isModule.exists(msg.sender));
        _;
    }

    modifier onlyExecutor() {
        require(
            (msg.sender == userAccountManager) ||
            (isModule.exists(msg.sender))
        );
        _;
    }
}