pragma ton-solidity >= 0.47.0;

import './interfaces/IModule.sol';

import '../utils/libraries/MsgFlag.sol';

contract SupplyModule is IModule, IContractStateCache {

    using UFO for uint256;
    using FPO for fraction;

    address marketAddress;
    address userAccountManager;
    address owner;

    mapping (uint32 => MarketInfo) marketInfo;
    mapping (address => fraction) tokenPrices;
    
    constructor(address _owner, address _marketAddress, address _userAccountManager) public {
        tvm.accept();
        owner = _owner;
        marketAddress = _marketAddress;
        userAccountManager = _userAccountManager;
    }

    function sendActionId() external override view responsible returns(uint8) {
        return {flag: MsgFlag.REMAINING_GAS} 0;
    }

    function updateCache(address tonWallet, mapping (uint32 => MarketInfo) marketInfo_, mapping (address => fraction) tokenPrices_) external override onlyMarket {
        marketInfo = marketInfo_;
        tokenPrices = tokenPrices_;
        tonWallet.transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    function performAction(uint32 marketId, TvmCell args) external override onlyMarket {
        TvmSlice ts = args.toSlice();
        (address tonWallet, address userTip3Wallet, uint128 tokenAmount) = ts.decode(address, address, uint128);
        uint256 tokensToSupply = SupplyTokensLib.calculateSupply(tokenAmount, marketInfo[marketId]);

        MarketDelta marketDelta;
        marketDelta.currentPoolBalance.delta = tokenAmount;
        marketDelta.currentPoolBalance.positive = true;
        marketDelta.totalSupply.delta = tokenAmount;
        marketDelta.totalSupply.positive = true;

        IContractStateCacheRoot(marketAddress).receiveCacheDelta{
            value: msg.value/4
        }(tonWallet, marketDelta);

        IUAMUserAccount(userAccountManager).writeSupplyInfo{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, userTip3Wallet, marketId, tokensToSupply, tokenAmount);
    }

    function setMarketAddress(address _marketAddress) external onlyOwner {
        marketAddress = _marketAddress;
    }
    
    function getMarketAddress() external view responsible returns(address) {
        return {flag: MsgFlag.REMAINING_GAS} marketAddress;
    }

    function setUserAccountManagerAddress(address _userAccountManager) external onlyOwner {
        userAccountManager = _userAccountManager;
    }

    function getUserAccountManagerAddress() external view responsible returns(address) {
        return {flag: MsgFlag.REMAINING_GAS} marketAddress;
    }

    modifier onlyMarket() {
        require(msg.sender == marketAddress);
        tvm.rawReserve(msg.value, 2);
        _;
    }

    modifier onlyUserAccountManager() {
        require(msg.sender == userAccountManager);
        tvm.rawReserve(msg.value, 2);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        tvm.rawReserve(msg.value, 2);
        _;
    }
}