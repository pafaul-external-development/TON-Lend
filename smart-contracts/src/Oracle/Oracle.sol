pragma ton-solidity >= 0.43.0;
pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "./interfaces/IOracleService.sol";
import "./interfaces/IOracleUpdatePrices.sol";
import "./interfaces/IOracleReturnPrices.sol";
import "./interfaces/IOracleManageTokens.sol";

import "./libraries/CostConstants.sol";
import "./libraries/OracleErrorCodes.sol";

import "../utils/libraries/MsgFlag.sol";
import "../utils/Dex/IDexPair.sol";
import "../utils/interfaces/IUpgradableContract.sol";

contract Oracle is IOracleService, IOracleUpdatePrices, IOracleReturnPrices, IOracleManageTokens, IUpgradableContract {
    // For uniquencess of contract
    uint256 static nonce;

    // Variables for prices
    // Token root => MarketPriceInfo
    mapping(address => MarketPriceInfo) prices;
    // Swap pair address to token root
    mapping(address => address) swapPairToTokenRoot;

    // Information for update
    uint32 contractCodeVersion;

    // Owner info
    uint256 private ownerPubkey;
    address private ownerAddress;

    /*********************************************************************************************************/
    // Base functions - for deploying and upgrading contract
    // We are using Platform so constructor is not available
    constructor(address _owner, uint256 _ownerPubkey) public {
        tvm.accept();
        ownerAddress = _owner;
        ownerPubkey = _ownerPubkey;
    }

    /*  Upgrade Data for version 1 (from version 0):
        bits:
            address root
            uint8 contractType
            uint32 codeVersion
        refs:
            1. platformCode
            2. mappingStorage
                bits:
                    -
                refs:
                    1. mapping(address => MarketPriceInfo) prices
                    2. mapping(address => address) swapPairToTokenRoot
            3. updateParams

     */
    /**
     * @param code New contract code
     * @param updateParams Extrenal parameters used during update
     * @param codeVersion New code version
     */
    function upgradeContractCode(TvmCell code, TvmCell updateParams, uint32 codeVersion) override external onlyOwner {
        tvm.accept();

        tvm.setcode(code);
        tvm.setCurrentCode(code);

        onCodeUpgrade(
            nonce,
            prices,
            swapPairToTokenRoot,
            ownerPubkey,
            ownerAddress,
            updateParams,
            codeVersion
        );
    }

    function onCodeUpgrade(
        uint256,
        mapping(address => MarketPriceInfo),
        mapping(address => address),
        uint256,
        address,
        TvmCell,
        uint32
    ) private {

    }

    /*********************************************************************************************************/
    // Service functions
    function getVersion() override external responsible view returns (uint32) { 
        tvm.rawReserve(msg.value, 2);
        return { value: 0, bounce: false, flag: MsgFlag.REMAINING_GAS } contractCodeVersion;
    }

    function getDetails() override external responsible view returns (OracleServiceInformation) {
        tvm.rawReserve(msg.value, 2);
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
     * @param tokenRoot Address of token root to update
     * @param tokens Amount of tokens in swap pair
     * @param usd Amount of usd in swap pair
     */
    function externalUpdatePrice(address tokenRoot, uint128 tokens, uint128 usd) override external onlyOwner onlyKnownTokenRoot(tokenRoot) {
        if (msg.sender.value == 0) {
            tvm.accept();
        } else {
            tvm.rawReserve(msg.value, 2);
        }

        prices[tokenRoot].tokens = tokens;
        prices[tokenRoot].usd = usd;

        address(ownerAddress).transfer({value: 0, flag: 64});
    }

    /**
     * @param tokenRoot Address of token root to update
     */
    function internalUpdatePrice(address tokenRoot) override external onlyKnownTokenRoot(tokenRoot) {
        tvm.rawReserve(msg.value, 2);
        IDexPair(prices[tokenRoot].swapPair).getBalances{
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
        address affectedToken = swapPairToTokenRoot[msg.sender];
        prices[affectedToken].tokens = prices[affectedToken].isLeft ? updatedPrice.left_balance : updatedPrice.right_balance;
        prices[affectedToken].usd = prices[affectedToken].isLeft ? updatedPrice.right_balance : updatedPrice.left_balance;
    }

    /*********************************************************************************************************/
    // Get token price info
    /**
     * @param tokenRoot Address of token root
     * @param payload Payload attached to message (contains information about operation)
     */
    function getTokenPrice(address tokenRoot, TvmCell payload) override external responsible view returns(address, uint128, uint128, TvmCell) {
        tvm.rawReserve(msg.value, 2);
        return { value: 0, bounce: false, flag: MsgFlag.REMAINING_GAS } (tokenRoot, prices[tokenRoot].tokens, prices[tokenRoot].usd, payload);
    }

    /**
     * @param payload Payload attached to message (contains information about operation)
     */
    function getAllTokenPrices(TvmCell payload) override external responsible view returns (mapping(address => MarketPriceInfo), TvmCell) {
        tvm.rawReserve(msg.value, 2);
        return { value: 0, bounce: false, flag: MsgFlag.REMAINING_GAS } (prices, payload);
    }

    /*********************************************************************************************************/
    // Manage tokens
    /**
     * @param tokenRoot Address of token root
     * @param swapPairAddress Address of swap pair to fetch price information from
     * @param isLeft Is token on the left side or on the right (check internalGetUpdatedPrice)
     */
    function addToken(address tokenRoot, address swapPairAddress, bool isLeft) override external onlyOwner {
        tvm.accept();
        swapPairToTokenRoot[swapPairAddress] = tokenRoot;
        prices[tokenRoot] = MarketPriceInfo(swapPairAddress, isLeft, 0, 0);
        this.internalUpdatePrice{value: CostConstants.TOKEN_INITIAL_UPDATE_PRICE, bounce: false}(tokenRoot);
    }

    /**
     * @param tokenRoot Address of token root
     */
    function removeToken(address tokenRoot) override external onlyOwner {
        tvm.accept();
        delete swapPairToTokenRoot[prices[tokenRoot].swapPair];
        delete prices[tokenRoot];
    }

    /*********************************************************************************************************/
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == ownerAddress || msg.pubkey() == ownerPubkey, OracleErrorCodes.ERROR_NOT_OWNER);
        _;
    }

    modifier onlyTrustedSwapPair() {
        require(swapPairToTokenRoot.exists(msg.sender), OracleErrorCodes.ERROR_NOT_KNOWN_SWAP_PAIR);
        _;
    }

    modifier onlyKnownTokenRoot(address _tokenRoot) {
        require(prices.exists(_tokenRoot), OracleErrorCodes.ERROR_NOT_KNOWN_TOKEN_ROOT);
        _;
    }
}