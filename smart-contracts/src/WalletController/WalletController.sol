pragma ton-solidity >= 0.39.0;
pragma AbiHeader pubkey;
pragma AbiHeader expire;
pragma AbiHeader time;

import "./interfaces/IWalletControllerMarketInteractions.sol";
import "./interfaces/IWalletControllerMarketManagement.sol";

import "./libraries/CostConstants.sol";
import "./libraries/WalletControllerErrorCodes.sol";

import "../utils/interfaces/IUpgradableContract.sol";
import "../utils/TIP3/interfaces/ITokenWalletDeployedCallback.sol";
import "../utils/TIP3/interfaces/ITokensReceivedCallback.sol";

import "../utils/TIP3/interfaces/IRootTokenContract.sol";
import "../utils/TIP3/interfaces/ITONTokenWallet.sol";

import "../utils/libraries/MsgFlag.sol";

struct MarketTokenAddresses {
    address realToken;
    address virtualToken;
}

contract WalletController is IWalletControllerMarketInteractions, IWalletControllerMarketManagement, IUpgradableContract, ITokenWalletDeployedCallback, ITokensReceivedCallback {
    // Information for update
    address root;
    uint8 contractType;
    uint32 contractCodeVersion;
    TvmCell platformCode;

    // Root TIP-3 to market address mapping
    mapping (address => MarketTokenAddresses) marketAddresses; // Будет использовано для проверки корректности операций
    mapping (address => address) wallets;

    /*********************************************************************************************************/
    // Functions for deployment and upgrade
    constructor() public { revert(); } // Contract will be deployed using platform

    /*  Upgrade Data for version 0 (from Platform):
        bits:
            address root
            uint8 platformType
            address gasTo ?
        refs:
            1. platformCode
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
    }

    /*  Upgrade data for version 1 (from 0):
        bits:
            address root
            uint8 platformType
        refs:
            1. TvmCell platformCode
            2. mappingStorage:
                refs:
                    1. mapping(address => MarketTokenAddresses) marketAddresses
                    2. mapping(address => address) wallets
     */
    /**
     * @param code New contract code
     * @param updateParams Extrenal parameters used during update
     * @param codeVersion_ New code version
     * @param contractType_ Contract type of received update
     */
    function upgradeContractCode(TvmCell code, TvmCell updateParams, uint32 codeVersion_, uint8 contractType_) override external onlyRoot correctContractType(contractType_) {
        contractCodeVersion = codeVersion_;
        
        TvmBuilder builder;
        builder.store(root);
        builder.store(contractType);
        builder.store(platformCode);

        TvmBuilder mappingStorage;
        TvmBuilder marketStorage;
        marketStorage.store(marketAddresses);
        TvmBuilder walletStorage;
        walletStorage.store(wallets);

        mappingStorage.store(marketStorage.toCell());
        mappingStorage.store(walletStorage.toCell());

        builder.store(mappingStorage);
        onCodeUpgrade(builder.toCell());
    }

    /*********************************************************************************************************/
    // Market functions
    /**
     * @param market Address of new market
     * @param realTokenRoot Address of market's real token root (ex. USDT)
     * @param virtualTokenRoot Address of market's virtual token root (ex. vUSDT)
     */
    function addMarket(address market, address realTokenRoot, address virtualTokenRoot) external override onlyRoot {
        marketAddresses[market] = MarketTokenAddresses(realTokenRoot, virtualTokenRoot);

        wallets[realTokenRoot] = address.makeAddrStd(0, 0);
        wallets[virtualTokenRoot] = address.makeAddrStd(0, 0);
        addWallet(realTokenRoot);
        addWallet(virtualTokenRoot);
    }

    /**
     * @param market Address of market to remove
     */
    function removeMarket(address market) external override onlyRoot {
        MarketTokenAddresses marketTokenAddresses = marketAddresses[market];

        delete wallets[marketTokenAddresses.realToken];
        delete wallets[marketTokenAddresses.virtualToken];
        delete marketAddresses[market];
    }

    /**
     * @param tokenRoot Address of token root
     * @param destination Address of TIP-3 wallet to transfer tokens to
     * @param amount Amount of TIP-3 tokens to trasfer
     * @param payload Attached payload
     * @param sendGasTo Where to send remaining gas
     */
    function transferTokensToWallet(address tokenRoot, address destination, uint128 amount, TvmCell payload, address sendGasTo) external override view onlyMarket {
        address market = msg.sender;
        require(marketAddresses[market].virtualToken == tokenRoot || marketAddresses[market].realToken == tokenRoot);
        ITONTokenWallet(wallets[tokenRoot]).transfer{value: MsgFlag.REMAINING_GAS}(destination, amount, 0, sendGasTo, true, payload);
    }

    /*********************************************************************************************************/
    // Wallet functionality
    /**
     * @param tokenRoot Address of token root to request wallet deploy
     */
    function addWallet(address tokenRoot) private pure {
        IRootTokenContract(tokenRoot).deployEmptyWallet{value: CostConstants.WALLET_DEPLOY_COST}(
            CostConstants.WALLET_DEPLOY_GRAMS,
            0,
            address(this),
            address(this)
        );
    }

    /**
     * @param root_ Receive deployed wallet address
     */
    function notifyWalletDeployed(address root_) external override onlyExisingTIP3Root(root_) {
        tvm.accept();
        if (wallets[root_].value == 0) {
            wallets[root_] = msg.sender;
        }
    }

    function tokensReceivedCallback(
        address token_wallet,
        address token_root,
        uint128 amount,
        uint256 sender_public_key,
        address sender_address,
        address sender_wallet,
        address original_gas_to,
        uint128 updated_balance,
        TvmCell payload
    ) external override onlyOwnWallet(token_root, token_wallet) {

    }

    /*********************************************************************************************************/
    // modifiers
    
    modifier onlyRoot() {
        require(msg.sender == root, WalletControllerErrorCodes.ERROR_MSG_SENDER_IS_NOT_ROOT);
        _;
    }

    modifier onlyMarket() {
        require(marketAddresses.exists(msg.sender), WalletControllerErrorCodes.ERROR_MSG_SENDER_IS_NOT_MARKET);
        _;
    }

    /**
     * @param tokenRoot Root address of TIP-3 token
     * @param tokenWallet Address of TIP-3 wallet
     */
    modifier onlyOwnWallet(address tokenRoot, address tokenWallet) {
        require(wallets[tokenRoot] == tokenWallet, WalletControllerErrorCodes.ERROR_MSG_SENDER_IS_NOT_OWN_WALLET);
        _;
    }

    /**
     * @param rootAddress msg.sender parameter
     */
    modifier onlyExisingTIP3Root(address rootAddress) {
        require(wallets.exists(rootAddress), WalletControllerErrorCodes.ERROR_TIP3_ROOT_IS_UNKNOWN);
        _;
    }

    /**
     * @param contractType_ Received contract type
     */
    modifier correctContractType(uint8 contractType_) {
        require(contractType == contractType_, WalletControllerErrorCodes.ERROR_INVALID_CONTRACT_TYPE);
        _;
    }

}
