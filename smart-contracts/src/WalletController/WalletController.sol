pragma ton-solidity >= 0.39.0;
pragma AbiHeader pubkey;
pragma AbiHeader expire;
pragma AbiHeader time;

import "./interfaces/IWalletControllerMarketInteractions.sol";
import "./interfaces/IWalletControllerMarketManagement.sol";
import "./interfaces/IWalletControllerGetters.sol";

import "./libraries/CostConstants.sol";
import "./libraries/WalletControllerErrorCodes.sol";
import "./libraries/OperationCodes.sol";

import "../Market/interfaces/IMarketInteractions.sol";

import "../utils/interfaces/IUpgradableContract.sol";
import "../utils/TIP3/interfaces/ITokenWalletDeployedCallback.sol";
import "../utils/TIP3/interfaces/ITokensReceivedCallback.sol";

import "../utils/TIP3/interfaces/IRootTokenContract.sol";
import "../utils/TIP3/interfaces/ITONTokenWallet.sol";

import "../utils/libraries/MsgFlag.sol";

contract WalletController is IWCMInteractions, IWalletControllerMarketManagement, IWalletControllerGetters, IUpgradableContract, ITokenWalletDeployedCallback, ITokensReceivedCallback {
    // Information for update
    address root;
    uint8 contractType;
    uint32 contractCodeVersion;
    TvmCell platformCode;

    address marketAddress;

    // Root TIP-3 to market address mapping
    mapping (address => MarketTokenAddresses) marketAddresses; // Будет использовано для проверки корректности операций
    mapping (address => address) wallets;

    mapping (uint32 => MarketTokenAddresses) marketTIP3Info;

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
            2. initialData
            bits: 
                1. marketAddress
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
        TvmSlice addressInfo = dataSlice.loadRefAsSlice();
        (marketAddress) = addressInfo.decode(address);
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

        tvm.setcode(code);
        tvm.setCurrentCode(code);
        
        onCodeUpgrade(builder.toCell());
    }

    /*********************************************************************************************************/
    // Market functions
    function setMarketAddress(address market_) external override onlyRoot {
        tvm.accept();
        marketAddress = market_;
    }

    function addMarket(uint32 marketId, address realTokenRoot, address virtualTokenRoot) external override onlyMarket {
        tvm.rawReserve(msg.value, 2);
        marketTIP3Info[marketId] = MarketTokenAddresses({
            realToken: realTokenRoot, 
            virtualToken: virtualTokenRoot,
            realTokenWallet: address.makeAddrStd(0, 0),
            virtualTokenWallet: address.makeAddrStd(0, 0)
        });

        wallets[realTokenRoot] = address.makeAddrStd(0, 0);
        wallets[virtualTokenRoot] = address.makeAddrStd(0, 0);

        addWallet(realTokenRoot);
        addWallet(virtualTokenRoot);
    }

    /**
     * @param marketId Id of market to remove
     */
    function removeMarket(uint32 marketId) external override onlyRoot {
        tvm.accept();
        MarketTokenAddresses marketTokenAddresses = marketTIP3Info[marketId];

        delete wallets[marketTokenAddresses.realToken];
        delete wallets[marketTokenAddresses.virtualToken];
        delete marketTIP3Info[marketId];
    }

    function transferTokensToWallet(address tonWallet, address tokenRoot, address userTip3Wallet, uint256 toPayout) external override view onlyMarket {
        TvmCell empty;
        ITONTokenWallet(wallets[tokenRoot]).transfer{value: MsgFlag.REMAINING_GAS}(userTip3Wallet, uint128(toPayout), 0, tonWallet, true, empty);
    }

    /*********************************************************************************************************/
    // Wallet functionality
    /**
     * @param tokenRoot Address of token root to request wallet deploy
     */
    function addWallet(address tokenRoot) private pure {
        IRootTokenContract(tokenRoot).deployEmptyWallet{
            value: CostConstants.WALLET_DEPLOY_COST
        }(
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
        uint256, // sender_public_key,
        address sender_address,
        address sender_wallet,
        address, // original_gas_to,
        uint128, // updated_balance,
        TvmCell payload
    ) external override onlyOwnWallet(token_root, token_wallet) {
        tvm.rawReserve(msg.value, 2);
        TvmSlice ts = payload.toSlice();
        uint8 operation = ts.decode(uint8);
        TvmSlice args = ts.loadRefAsSlice();
        if (operation == OperationCodes.SUPPLY_TOKENS) {
            (address tonWallet, address userTip3Wallet) = args.decode(address, address);
            IMarketOperations(marketAddress).supplyTokensToMarket{
                flag: MsgFlag.REMAINING_GAS
            }(token_root, tonWallet, userTip3Wallet, amount);
        } else if (operation == OperationCodes.REPAY_TOKENS) {
            (address tonWallet, uint8 loanId) = args.decode(address, uint8);
            IMarketOperations(marketAddress).repayBorrow{
                flag: MsgFlag.REMAINING_GAS
            }(token_root, tonWallet, sender_wallet, amount, loanId);
        } else if (operation == OperationCodes.WITHDRAW_TOKENS) {
            (address tonWallet, address userTip3Wallet) = args.decode(address, address);
            IMarketOperations(marketAddress).withdrawVToken{
                flag: MsgFlag.REMAINING_GAS
            }(token_root, tonWallet, userTip3Wallet, sender_wallet, amount);
        } else {
            address(sender_address).transfer({value: 0, flag: 64});
        }
    }

    /*********************************************************************************************************/
    // Getter functions
    function getMarketAddresses(uint32 marketId) external override view responsible returns(MarketTokenAddresses) {
        return {flag: MsgFlag.REMAINING_GAS} marketTIP3Info[marketId];
    }

    function getAllMarkets() external override view responsible returns(mapping(uint32 => MarketTokenAddresses)) {
        return {flag: MsgFlag.REMAINING_GAS} marketTIP3Info;
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

    /*********************************************************************************************************/
    // Functions for payload creation

    function createSupplyPayload(address userAddress, address userVTokenWallet) external pure returns(TvmCell) {
        TvmBuilder tb;
        tb.store(OperationCodes.SUPPLY_TOKENS);
        TvmBuilder op;
        op.store(userAddress);
        op.store(userVTokenWallet);
        tb.store(op.toCell());

        return tb.toCell();
    }

    function createRepayPayload(address userAddress, uint8 loanId) external pure returns(TvmCell) {
        TvmBuilder tb;
        tb.store(OperationCodes.REPAY_TOKENS);
        TvmBuilder op;
        op.store(userAddress);
        op.store(loanId);
        tb.store(op);

        return tb.toCell();
    }

    function createWithdrawPayload(address userAddress, address userTip3Wallet) external pure returns(TvmCell) {
        TvmBuilder tb;
        tb.store(OperationCodes.WITHDRAW_TOKENS);
        TvmBuilder op;
        op.store(userAddress);
        op.store(userTip3Wallet);
        tb.store(op);

        return tb.toCell();
    }
}
