pragma ton-solidity >= 0.39.0;
pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "./interfaces/IOracleService.sol";
import "./interfaces/IOracleUpdatePrices.sol";
import "./interfaces/IOracleReturnPrices.sol";
import "./interfaces/IOracleManageMarkets.sol";

import "./libraries/CostConstants.sol";
import "./libraries/OracleErrorCodes.sol";

import "../utils/libraries/MsgFlag.sol";
import "../utils/Dex/IDexPair.sol";
import "../utils/interfaces/IUpgradableContract.sol";

// TODO: use tokens, not markets change getMarketPrice to getTokenPrice 
contract Oracle is IOracleService, IOracleUpdatePrices, IOracleReturnPrices, IOracleManageMarkets, IUpgradableContract {
    // For uniquencess of contract
    uint256 public nonce;

    // Variables for prices
    mapping(address => MarketPriceInfo) prices;
    mapping(address => address) swapPairToMarket;

    // Information for update
    address root;
    uint8 contractType;
    uint32 contractCodeVersion;
    TvmCell platformCode;


    // Owner info
    uint256 private ownerPubkey;
    address private ownerAddress;

    /*********************************************************************************************************/
    // Base functions - for deploying and upgrading contract
    // We are using Platform so constructor is not available
    constructor() public {
        revert();
    }

    /*  Upgrade Data for version 1 (from version 0):
        bits:
            address root
            uint8 contractType
        refs:
            1. platformCode
            2. mappingStorage
                bits:
                    -
                refs:
                    1. mapping(address => MarketPriceInfo) prices
                    2. mapping(address => address) swapPairToMarket
            3. updateParams

     */
    /**
     * @param code New contract code
     * @param updateParams Extrenal parameters used during update
     * @param codeVersion_ New code version
     * @param contractType_ Contract type of received update
     */
    function upgradeContractCode(TvmCell code, TvmCell updateParams, uint32 codeVersion_, uint8 contractType_) override external onlyRoot correctContractType(contractType_) {
        tvm.accept();

        contractCodeVersion = codeVersion_;

        TvmBuilder builder;
        builder.store(root);
        builder.store(contractType);
        builder.store(platformCode);

        // Store owner info
        TvmBuilder ownerInfo;
        ownerInfo.store(ownerPubkey);
        ownerInfo.store(ownerAddress);

        // Store mappings
        TvmBuilder mappingStorage;
        TvmBuilder pricesInfo;
        pricesInfo.store(prices);

        TvmBuilder addressMapping;
        addressMapping.store(prices);

        mappingStorage.store(pricesInfo.toCell());
        mappingStorage.store(addressMapping.toCell());

        builder.store(addressMapping.toCell());


        builder.store(updateParams);

        tvm.setcode(code);
        tvm.setCurrentCode(code);

        onCodeUpgrade(builder.toCell());
    }

    /*  Upgrade Data for version 0 (from Platform):
        bits:
            address root
            uint8 platformType
            address gasTo ?
        refs:
            1. platformCode
            2. initialData:
                bits:
                    uint256 ownerPubkey
                    address ownerAddress
     */
    
    /**
     * @param data Data builded in upgradeContractCode
     */
    function onCodeUpgrade(TvmCell data) private {
        TvmSlice dataSlice = data.toSlice();
        (address root_, uint8 platformType) = dataSlice.decode(address, uint8);
        root = root_;
        contractType = platformType;

        platformCode = dataSlice.loadRef();         // Loading platform code
        TvmSlice ref = dataSlice.loadRefAsSlice();  // Loading initial parameters
        (ownerPubkey, ownerAddress) = ref.decode(uint256, address);
    }

    /*********************************************************************************************************/
    // Service functions
    function getVersion() override external responsible view returns (uint32) { 
        return { value: 0, bounce: false, flag: MsgFlag.REMAINING_GAS } contractCodeVersion;
    }

    function getDetails() override external responsible view returns (OracleServiceInformation) {
        return { value: 0, bounce: false, flag: MsgFlag.REMAINING_GAS } OracleServiceInformation(contractCodeVersion, ownerAddress, ownerPubkey);
    }

    /**
     * @param newOwnerPubkey New pubkey that can update market prices and manage markets
     */
    function changeOwnerPubkey(uint256 newOwnerPubkey) override external onlyOwner {
        tvm.accept();
        ownerPubkey = newOwnerPubkey;
    }

    /**
     * @param newOwnerAddress New address that can update market prices and manage markets
     */
    function changeOwnerAddress(address newOwnerAddress) override external onlyOwner {
        tvm.accept();
        ownerAddress = newOwnerAddress;
    }

    /*********************************************************************************************************/
    // Update price functions
    /**
     * @param market Address of market to update
     * @param costToUSD Cost of token to USD
     */
    function externalUpdatePrice(address market, uint256 costToUSD) override external onlyOwner {
        tvm.accept();
        prices[market].priceToUSD = costToUSD;
    }

    /**
     * @param market Address of market to update
     */
    function internalUpdatePrice(address market) override external {
        tvm.rawReserve(msg.value, 2);
        IDexPair(prices[market].swapPair).getBalances{
            value: 0, 
            bounce: true, 
            flag: MsgFlag.REMAINING_GAS,
            callback: this.internalGetUpdatedPrice
        }();
    }

    /**
     * @param updatedPrice Received price information
     */
    function internalGetUpdatedPrice(IDexPairBalances updatedPrice) override external onlyTrustedSwapPair {
        tvm.rawReserve(msg.value, 2);
        address affectedMarket = swapPairToMarket[msg.sender];
        prices[affectedMarket].priceToUSD = prices[affectedMarket].isLeft ? updatedPrice.left_balance/updatedPrice.right_balance : updatedPrice.right_balance/updatedPrice.left_balance;
    }

    /*********************************************************************************************************/
    // Get market price info
    /**
     * @param market Address of market
     * @param payload Payload attached to message (contains information about operation)
     */
    function getMarketPrice(address market, TvmCell payload) override external responsible view returns(uint256, TvmCell) {
        return { value: 0, bounce: false, flag: MsgFlag.REMAINING_GAS } (prices[market].priceToUSD, payload);
    }

    /**
     * @param payload Payload attached to message (contains information about operation)
     */
    function getAllMarketsPrices(TvmCell payload) override external responsible view returns (mapping(address => MarketPriceInfo), TvmCell) {
        return { value: 0, bounce: false, flag: MsgFlag.REMAINING_GAS } (prices, payload);
    }

    /*********************************************************************************************************/
    // Manage markets
    /**
     * @param market Address of market
     * @param swapPairAddress Address of swap pair to fetch price information from
     * @param isLeft Is token on the left side or on the right (check internalGetUpdatedPrice)
     */
    function addMarket(address market, address swapPairAddress, bool isLeft) override external onlyOwner {
        tvm.accept();
        swapPairToMarket[swapPairAddress] = market;
        prices[market] = MarketPriceInfo(market, swapPairAddress, isLeft, 0);
        this.internalUpdatePrice{value: CostConstants.MARKET_INITIAL_UPDATE_PRICE, bounce: false}(market);
    }

    /**
     * @param market Address of market
     */
    function removeMarket(address market) override external onlyOwner {
        tvm.accept();
        delete swapPairToMarket[prices[market].swapPair];
        delete prices[market];
    }

    /*********************************************************************************************************/
    // Modifiers
    modifier onlyRoot() {
        require(msg.sender == root, OracleErrorCodes.ERROR_NOT_ROOT);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == ownerAddress || msg.pubkey() == ownerPubkey, OracleErrorCodes.ERROR_NOT_OWNER);
        _;
    }

    modifier trusted() {
        require(msg.sender == ownerAddress || msg.sender == root || msg.pubkey() == ownerPubkey, OracleErrorCodes.ERROR_NOT_TRUSTED);
        _;
    }

    modifier onlyTrustedSwapPair() {
        require(swapPairToMarket.exists(msg.sender), OracleErrorCodes.ERROR_NOT_KNOWN_SWAP_PAIR);
        _;
    }

    /**
     * @param contractType_ Received contractType parameter
     */
    modifier correctContractType(uint8 contractType_) {
        require(contractType == contractType_, OracleErrorCodes.ERROR_INVALID_CONTRACT_TYPE);
        _;
    }
}