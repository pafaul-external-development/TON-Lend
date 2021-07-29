pragma ton-solc ^0.39.0;
pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "./interfaces/IOracleService.sol";
import "./interfaces/IOracleUpdatePrices.sol";
import "./interfaces/IOracleReturnPrices.sol";
import "./interfaces/IOracleUpgradable.sol";

import "./libraries/CostConstants.sol";

import "../utils/MsgFlag.sol";
import "../utils/IDexPair.sol";

contract Oracle is IOracleService, IOracleUpdatePrices, IOracleReturnPrices, IOracleUpgradable {
    // Variables for prices
    mapping(address => MarketPriceInfo) prices;
    mapping(address => address) swapPairToMarket;

    // Owner info
    uint256 private ownerPubkey;
    address private ownerAddress;

    // Service info
    uint32 private codeVersion; 

    // Base functions
    constructor() public {
        tvm.accept();
    }

    // Service functions
    function getVersion() override external responsible view returns (uint256) { 
        return { value: 0, bounce: false, flag: MsgFlag.REMAINING_GAS } codeVersion;
    }

    function getDetails() override external responsible view returns (OracleServiceInformation) {
        return { value: 0, bounce: false, flag: MsgFlag.REMAINING_GAS } OracleServiceInformation(codeVersion, ownerAddress, ownerPubkey);
    }

    function changeOwnerPubkey(uint256 newOwnerPubkey) override external onlyOwner {
        tvm.accept();
        ownerPubkey = newOwnerPubkey;
    }

    function changeOwnerAddress(address newOwnerAddress) override external onlyOwner {
        tvm.accept();
        ownerAddress = newOwnerAddress;
    }

    // Update price functions
    function externalUpdatePrice(address market, uint256 costToUSD) override external onlyOwner {
        tvm.accept();
        prices[market].priceToUSD = costToUSD;
    }

    function internalUpdatePrice(address market) override external {
        tvm.rawReserve(msg.value, 2);
        IDexPair(prices[market].swapPair).getBalances{value: 0, bounce: true, flag: MsgFlag.REMAINING_GAS}();
    }

    function internalFullUpdate() override external {

    }

    function internalGetUpdatedPrice(IDexPairBalances updatedPrice) override external onlyTrustedSwapPair {
        tvm.rawReserve(msg.value, 2);
        address affectedMarket = swapPairToMarket[msg.sender];
        prices[affectedMarket].priceToUSD = prices[affectedMarket].isLeft ? updatedPrice.left_balance/updatedPrice.right_balance : updatedPrice.right_balance/updatedPrice.left_balance;
    }


    // Get market price info
    function getMarketPrice(address market) override external view returns(uint256 priceToUSD, TvmCell payload) {
        return { value: 0, bounce: false, flag: MsgFlag.REMAINING_GAS } (prices[market].priceToUSD, payload);
    }

    function getAllMarketsPrices() override external view returns (mapping(address => MarketPriceInfo) prices, TvmCell payload) {
        return { value: 0, bounce: false, flag: MsgFlag.REMAINING_GAS } (prices, payload);
    }

    // Manage markets
    function addMarket(address market, address swapPairAddress, bool isLeft) override external onlyOwner {
        tvm.accept();
        swapPairToMarket[swapPairAddress] = market;
        prices[market] = MarketPriceInfo(market, swapPair, isLeft, 0);
        this.internalUpdatePrice{value: CostConstants.MARKET_INITIAL_UPDATE_PRICE, bounce: false}(market);
    }

    function removeMarket(address market) virtual external onlyOwner {

    }

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == onwerAddress || msg.pubkey() == ownerPubkey);
        _;
    }    

    modifier onlyTrustedSwapPair() {
        require(swapPairToMarket.exists(msg.sender));
        _;
    }
}