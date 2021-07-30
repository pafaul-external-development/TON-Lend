pragma ton-solidity >= 0.39.0;
pragma AbiHeader pubkey;
pragma AbiHeader expire;
pragma AbiHeader time;

import "./interfaces/ITIP3ControllerMarketInteractions.sol";
import "./interfaces/ITIP3ControllerMarketManagement.sol";

import "../utils/interfaces/IUpgradableContract.sol";
import "../utils/interfaces/ITokenWalletDeployedCallback.sol";
import "../utils/interfaces/ITokensReceivedCallback.sol";

import "../utils/interfaces/IRootTokenContract.sol";
import "../utils/interfaces/ITONTokenWallet.sol";

struct MarketTokenAddresses {
    address realToken;
    address virtualToken;
}

contract TIP3Controller is ITIP3ControllerMarketInteractions, ITIP3ControllerMarketManagement, IUpgradableContract, ITokenWalletDeployedCallback, ITokensReceivedCallback {
    // Information for update
    address root;
    uint8 contractType;
    uint32 contractCodeVersion;
    TvmCell platformCode;

    // Root TIP-3 to market address mapping
    mapping (address => MarketTokenAddresses) marketAddresses; // Будет использовано для проверки корректности операций
    mapping (address => address) wallets;

    constructor() public { revert(); } // Contract will be deployed using platform

    /*  Upgrade Data for version 0 (from Platform):
        bits:
            address root
            uint8 platformType
            address gasTo ?
        refs:
            1. platformCode
     */
    function onCodeUpgrade(TvmCell data) private {
        TvmSlice dataSlice = data.toSlice();
        (address root, uint8 contractType, address sendGasTo) = dataSlice.decode(address, uint8, address);
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
    function upgradeContractCode(TvmCell code, TvmCell updateParams, uint32 codeVersion_, uint8 contractType_) override external onlyRoot correctContractType(contractType_) {
        contractCodeVersion = codeVersion_;
        
        TvmBuilder builder;
        builder.store(root);
        builder.store(platformType);
        builder.store(platformCode);

        TvmBuilder mappingStorage;
        TvmBuilder marketStorage;
        marketStorage.store(marketAddresses);
        TvmBuilder walletStorage;
        walletStorage.store(wallets);

        mappingStorage.store(marketAddresses.toCell());
        mappingStorage.store(wallets.toCell());

        builder.store(mappingStorage);
        onCodeUpgrade(builder.toCell());
    }


    function addMarket(address market, address realTokenRoot, address virtualTokenRoot) external onlyRoot {
        marketAddresses[market] = MarketTokenAddresses(realTokenRoot, virtualTokenRoot);

        wallets[realTokenRoot] = address.makeAddrStd(0, 0);
        wallets[virtualTokenRoot] = address.makeAddrStd(0, 0);
        addWallet(realTokenRoot);
        addWallet(virtualTokenRoot);
    }

    function removeMarket(address market) external {
        MarketTokenAddresses marketTokenAddresses = marketAddresses[market];

        delete wallets[marketTokenAddresses.realToken];
        delete wallets[marketTokenAddresses.virtualToken];
        delete marketAddresses[market];
    }

    function transferTokensToWallet(address tokenRoot, address destination, uint128 amount, TvmCell payload, address sendGasTo) external view onlyMarket {
        require(marketAddresses[market].virtualToken == tokenRoot || marketAddresses[market].realToken == tokenRoot);
        ITONTokenWallet(wallets[tokenRoot]).transfer{value: MsgFlags.REMAINING_GAS}(destination, amount, 0, sendGasTo, true, payload);
    }


    function addWallet(address tokenRoot) private {
        IRootTokenContract(tokenRoot).createEmptyWallet{value: CostConstants.WALLET_DEPLOY_COST}(
            CostConstants.WALLET_DEPLOY_GRAMS,
            0,
            address(this),
            address(this)
        );
    }

    function notifyWalletDeployed(address root_) external onlyExisingTIP3Root(root_) {
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
    ) external onlyOwnWallet(token_root, token_wallet) {

    }

    // modifiers
    modifier onlyExisingTIP3Root(address rootAddress) {
        require(wallets.exists(rootAddress));
        _;
    }

    modifier correctContractType(contractType_) {
        require(contractType == contractType_);
        _;
    }

    modifier onlyOwnWallet(address tokenRoot, address tokenWallet) {
        require(wallets[tokenRoot] == tokenWallet);
        _;
    }

    modifier onlyMarket() {
        require(marketAddresses.exists(msg.sender));
        _;
    }

    modifier onlyRoot() {
        require(msg.sender == root);
        _;
    }
}