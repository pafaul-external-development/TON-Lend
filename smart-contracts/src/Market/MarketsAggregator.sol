pragma ton-solidity >= 0.39.0;

import "./interfaces/IMarketInteractions.sol"; 
import "./interfaces/IMarketGetters.sol";

import "./libraries/CostConstants.sol";
import "./libraries/MarketErrorCodes.sol";

import "../Controllers/interfaces/ICCMarketDeployed.sol";

import "../TIP3Deployer/interfaces/ITIP3Deployer.sol";

import "../utils/interfaces/IUpgradableContract.sol";

import "../utils/libraries/MsgFlag.sol";

contract MarketAggregator is IMarketUAM, IUpgradableContract, IMarketOracle, IMarketSetters, IMarketTIP3Root, IMarketOwnerFunctions, IMarketGetters {

    // Information for update
    address root;
    uint8 contractType;
    uint32 contractCodeVersion;
    TvmCell platformCode;
    
    // owner info
    address owner;

    address userAccountManager;
    address tip3WalletController;
    address oracle;
    address tip3Deployer;
    mapping(uint32 => bool) createdMarkets;
    mapping(address => uint32) tokensToMarkets;
    mapping(uint32 => MarketInfo) marketsInfo;
    mapping(address => MarketPriceInfo) tokenPrices;
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
                        2. tip3WalletController
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
        (userAccountManager, tip3WalletController, oracle) = tmp.decode(address, address, address);
        tmp = initialData.loadRefAsSlice();
        (owner) = tmp.decode(address);
    }

    /*********************************************************************************************************/
    // Manage markets functions
    function createNewMarket(uint32 marketId, address realToken, uint32 kinkNom, uint32 kinkDenom, uint32 collNom, uint32 collDenom) external onlyOwner {
        tvm.rawReserve(msg.value, 2);
        if (!createdMarkets[marketId]) {
            createdMarkets[marketId] = true;

            marketsInfo[marketId] = MarketInfo({
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
     */
    function receiveNewTIP3Address(address tip3RootAddress, TvmCell payload) external override onlyTIP3Deployer {
        tvm.accept();
        TvmSlice s = payload.toSlice();
        uint32 marketId = s.decode(uint32);
        marketsInfo[marketId].virtualToken = tip3RootAddress;
        virtualTokenRoots[tip3RootAddress] = true;

        ICCMarketDeployed(root).marketDeployed{
            value: CostConstants.NOTIFY_CONTRACT_CONTROLLER,
            bounce: false
        }(marketId, marketsInfo[marketId].token, marketsInfo[marketId].virtualToken);
    }

    /*********************************************************************************************************/
    // Interactions with UserAccountManager

    function fetchInformationFromUserAccount(address userAccount, TvmCell payload) external override view onlySelf {
        tvm.rawReserve(msg.value, 2);
        IUAMUserAccount(userAccountManager).fetchInformationFromUserAccount{
            flag: MsgFlag.REMAINING_GAS
        }(userAccount, payload);
    } 

    function receiveInformationFromUser(address userAccount, TvmCell payload) external override onlyUserAccountManager {
        tvm.rawReserve(msg.value, 2);
    }

    /*********************************************************************************************************/
    // Interactions with oracle

    function updatePrice(address tokenRoot, TvmCell payload) internal view {
        IOracleReturnPrices(oracle).getTokenPrice{
            flag: 64,
            callback: this.receiveUpdatedPrice
        }(tokenRoot, payload);
    }

    function receiveUpdatedPrice(address tokenRoot, uint128 nom, uint128 denom, TvmCell payload) external override onlyOracle {
        tvm.rawReserve(msg.value, 2);
        tokenPrices[tokenRoot].tokens = nom;
        tokenPrices[tokenRoot].usd = denom;
    }

    function updateAllPrices(TvmCell payload) internal view {
        IOracleReturnPrices(oracle).getAllTokenPrices{
            flag: 64,
            callback: this.receiveAllUpdatedPrices
        }(payload);
    }

    function receiveAllUpdatedPrices(mapping(address => MarketPriceInfo) updatedPrices, TvmCell payload) external override onlyOracle {
        tvm.rawReserve(msg.value, 2);
        tokenPrices = updatedPrices;
    }

    function forceUpdatePrice(address tokenRoot) external override {
        tvm.rawReserve(msg.value, 2);
        TvmCell payload;
        updatePrice(tokenRoot, payload);
    }

    function forceUpdateAllPrices() external override {
        tvm.rawReserve(msg.value, 2);
        TvmCell payload;
        updateAllPrices(payload);
    }

    /*********************************************************************************************************/
    // Setters
    function setUserAccountManager(address userAccountManager_) external override onlyOwner {
        tvm.rawReserve(msg.value, 2);
        userAccountManager = userAccountManager_;
        address(msg.sender).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    function setTip3WalletController(address tip3WalletController_) external override onlyOwner {
        tvm.rawReserve(msg.value, 2);
        tip3WalletController = tip3WalletController_;
        address(msg.sender).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    function setOracleAddress(address oracle_) external override onlyOwner {
        tvm.rawReserve(msg.value, 2);
        oracle = oracle_;
        address(msg.sender).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    function transferOwnership(address newOwner) external override onlyOwner {
        tvm.rawReserve(msg.value, 2);
        owner = newOwner;
        address(msg.sender).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    /*********************************************************************************************************/
    // Getters
    function getServiceContractAddresses() external override view responsible returns(address userAccountManager_, address tip3WalletController_, address oracle_) {
        return {flag: MsgFlag.REMAINING_GAS} (userAccountManager, tip3WalletController, oracle);
    }

    function getMarketInformation(uint32 marketId) external override view responsible returns(MarketInfo) {
        return {flag: MsgFlag.REMAINING_GAS} marketsInfo[marketId];
    }

    function getAllMarkets() external override view responsible returns(mapping(uint32 => MarketInfo)) {
        return {flag: MsgFlag.REMAINING_GAS} marketsInfo;
    }

    function withdrawExtraTons(uint128 amount) external override onlyOwner {
        tvm.accept();
        address(owner).transfer({flag: 1, value: amount});
    }

    /*********************************************************************************************************/
    // Modificators

    modifier onlySelf() {
        require(msg.sender == address(this));
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyRoot() {
        require(msg.sender == root);
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracle);
        _;
    }

    modifier onlyTIP3Deployer() {
        require(msg.sender == tip3Deployer);
        _;
    }

    modifier onlyUserAccountManager() {
        require(msg.sender == userAccountManager);
        _;
    }

    modifier onlyTip3WalletController() {
        require(msg.sender == tip3WalletController);
        _;
    }

    modifier onlyRealTokenRoot() {
        require(realTokenRoots.exists(msg.sender));
        _;
    }

    modifier onlyVirtualTokenRoot() {
        require(virtualTokenRoots.exists(msg.sender));
        _;
    }

    modifier correctContractType(uint8 contractType_) {
        require(contractType == contractType_);
        _;
    }
}