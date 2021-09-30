pragma ton-solidity >= 0.43.0;
pragma AbiHeader pubkey;
pragma AbiHeader expire;
pragma AbiHeader time;

import "./interfaces/IWalletControllerMarketInteractions.sol";
import "./interfaces/IWalletControllerMarketManagement.sol";
import "./interfaces/IWalletControllerGetters.sol";

import "./libraries/CostConstants.sol";
import "./libraries/WalletControllerErrorCodes.sol";
import "./libraries/OperationCodes.sol";

import "../Market/interfaces/IMarketInterfaces.sol";

import "../utils/interfaces/IUpgradableContract.sol";
import "../utils/TIP3/interfaces/ITokenWalletDeployedCallback.sol";
import "../utils/TIP3/interfaces/ITokensReceivedCallback.sol";

import "../utils/TIP3/interfaces/IRootTokenContract.sol";
import "../utils/TIP3/interfaces/ITONTokenWallet.sol";

import "../utils/libraries/MsgFlag.sol";

contract WalletController is IWCMInteractions, IWalletControllerMarketManagement, IWalletControllerGetters, IUpgradableContract, ITokenWalletDeployedCallback, ITokensReceivedCallback {
    // Information for update
    uint32 contractCodeVersion;

    address owner;
    address marketAddress;

    // Root TIP-3 to market address mapping
    mapping (address => address) wallets;
    mapping (address => bool) realTokenRoots;
    mapping (address => bool) vTokenRoots;

    mapping (uint32 => MarketTokenAddresses) marketTIP3Info;

    /*********************************************************************************************************/
    // Functions for deployment and upgrade
    constructor() public { 
        tvm.accept();
        owner = msg.sender;
     } // Contract will be deployed using platform

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
     * @param codeVersion New code version
     */
    function upgradeContractCode(TvmCell code, TvmCell updateParams, uint32 codeVersion) override external onlyOwner {
        tvm.accept();

        tvm.setcode(code);
        tvm.setCurrentCode(code);
        
        onCodeUpgrade(
            owner,
            marketAddress,
            wallets,
            realTokenRoots,
            vTokenRoots,
            marketTIP3Info,
            updateParams,
            codeVersion
        );
    }

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
    function onCodeUpgrade(
        address, 
        address, 
        mapping(address => address), 
        mapping(address => bool), 
        mapping(address => bool), 
        mapping(uint32 => MarketTokenAddresses), 
        TvmCell, 
        uint32
    ) private {

    }

    /*********************************************************************************************************/
    // Market functions
    function setMarketAddress(address market_) external override onlyOwner {
        tvm.rawReserve(msg.value, 2);
        marketAddress = market_;

        address(owner).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    function addMarket(uint32 marketId, address realTokenRoot, address virtualTokenRoot) external override onlyTrusted {
        tvm.rawReserve(msg.value, 2);
        marketTIP3Info[marketId] = MarketTokenAddresses({
            realToken: realTokenRoot, 
            virtualToken: virtualTokenRoot,
            realTokenWallet: address.makeAddrStd(0, 0),
            virtualTokenWallet: address.makeAddrStd(0, 0)
        });

        realTokenRoots[realTokenRoot] = true;
        vTokenRoots[virtualTokenRoot] = true;

        wallets[realTokenRoot] = address.makeAddrStd(0, 0);
        wallets[virtualTokenRoot] = address.makeAddrStd(0, 0);

        addWallet(realTokenRoot);
        addWallet(virtualTokenRoot);

        address(marketAddress).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    /**
     * @param marketId Id of market to remove
     */
    function removeMarket(uint32 marketId) external override onlyTrusted {
        tvm.accept();
        MarketTokenAddresses marketTokenAddresses = marketTIP3Info[marketId];

        delete wallets[marketTokenAddresses.realToken];
        delete wallets[marketTokenAddresses.virtualToken];
        delete marketTIP3Info[marketId];
    }

    function transferTokensToWallet(address tonWallet, address tokenRoot, address userTip3Wallet, uint256 toPayout) external override view onlyTrusted {
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
            value: WCCostConstants.WALLET_DEPLOY_COST
        }(
            WCCostConstants.WALLET_DEPLOY_GRAMS,
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
        if (operation == OperationCodes.SUPPLY_TOKENS) {
            (address userTip3Wallet) = ts.decode(address);
            TvmBuilder tb;
            tb.store(sender_address);
            tb.store(userTip3Wallet);
            tb.store(amount);
            IMarketOperations(marketAddress).performOperationWalletController{
                flag: MsgFlag.REMAINING_GAS
            }(operation, token_root, tb.toCell());
        } else if (operation == OperationCodes.WITHDRAW_TOKENS) {
            (address userTip3Wallet) = ts.decode(address);
            TvmBuilder tb;
            tb.store(sender_address);
            tb.store(userTip3Wallet);
            tb.store(sender_wallet);
            tb.store(amount);
            IMarketOperations(marketAddress).performOperationWalletController{
                flag: MsgFlag.REMAINING_GAS
            }(operation, token_root, tb.toCell());
        } else if (operation == OperationCodes.REPAY_TOKENS) {
            (uint8 loanId) = ts.decode(uint8);
            TvmBuilder tb;
            tb.store(sender_address);
            tb.store(loanId);
            IMarketOperations(marketAddress).performOperationWalletController{
                flag: MsgFlag.REMAINING_GAS
            }(operation, token_root, tb.toCell());
        }
    }
    
    /*********************************************************************************************************/
    // Getter functions
    function getRealTokenRoots() external override view responsible returns(mapping(address => bool)) {
        return {flag: MsgFlag.REMAINING_GAS} realTokenRoots;
    }

    function getVirtualTokenRoots() external override view responsible returns(mapping(address => bool)) {
        return {flag: MsgFlag.REMAINING_GAS} vTokenRoots;
    }

    function getWallets() external override view responsible returns(mapping(address => address)) {
        return {flag: MsgFlag.REMAINING_GAS} wallets;
    }

    function getMarketAddresses(uint32 marketId) external override view responsible returns(MarketTokenAddresses) {
        return {flag: MsgFlag.REMAINING_GAS} marketTIP3Info[marketId];
    }

    function getAllMarkets() external override view responsible returns(mapping(uint32 => MarketTokenAddresses)) {
        return {flag: MsgFlag.REMAINING_GAS} marketTIP3Info;
    }

    /*********************************************************************************************************/
    // modifiers
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyMarket() {
        require(msg.sender == marketAddress, WalletControllerErrorCodes.ERROR_MSG_SENDER_IS_NOT_MARKET);
        _;
    }

    modifier onlyTrusted() {
        require(
            (msg.sender == owner) || 
            (msg.sender == marketAddress)
        );
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

    /*********************************************************************************************************/
    // Functions for payload creation

    function createSupplyPayload(address userVTokenWallet) external pure returns(TvmCell) {
        TvmBuilder tb;
        tb.store(OperationCodes.SUPPLY_TOKENS);
        TvmBuilder op;
        op.store(userVTokenWallet);
        tb.store(op.toCell());

        return tb.toCell();
    }

    function createRepayPayload(uint8 loanId) external pure returns(TvmCell) {
        TvmBuilder tb;
        tb.store(OperationCodes.REPAY_TOKENS);
        TvmBuilder op;
        op.store(loanId);
        tb.store(op.toCell());

        return tb.toCell();
    }

    function createWithdrawPayload(address userTip3Wallet) external pure returns(TvmCell) {
        TvmBuilder tb;
        tb.store(OperationCodes.WITHDRAW_TOKENS);
        TvmBuilder op;
        op.store(userTip3Wallet);
        tb.store(op.toCell());

        return tb.toCell();
    }
}
