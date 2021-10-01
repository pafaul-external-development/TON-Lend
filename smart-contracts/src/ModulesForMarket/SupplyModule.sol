pragma ton-solidity >= 0.47.0;

import './interfaces/IModule.sol';

import '../utils/libraries/MsgFlag.sol';

contract SupplyModule is IModule, IContractStateCache, IContractAddressSG {

    using UFO for uint256;
    using FPO for fraction;

    address marketAddress;
    address userAccountManager;
    address owner;

    mapping (uint32 => MarketInfo) marketInfo;
    mapping (address => fraction) tokenPrices;
    
    constructor() public {
        tvm.accept();
        owner = msg.sender;
    }

    function sendActionId() external override view responsible returns(uint8) {
        return {flag: MsgFlag.REMAINING_GAS} OperationCodes.SUPPLY_TOKENS;
    }

    function setMarketAddress(address _marketAddress) external override onlyOwner {
        tvm.rawReserve(msg.value, 2);
        marketAddress = _marketAddress;
        address(owner).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    function setUserAccountManager(address _userAccountManager) external override onlyOwner {
        tvm.rawReserve(msg.value, 2);
        userAccountManager = _userAccountManager;
        address(owner).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    function getContractAddresses() external override view responsible returns(address _owner, address _marketAddress, address _userAccountManager) {
        return {flag: MsgFlag.REMAINING_GAS} (owner, marketAddress, userAccountManager);
    }

    function updateCache(address tonWallet, mapping (uint32 => MarketInfo) _marketInfo, mapping (address => fraction) _tokenPrices) external override onlyMarket {
        marketInfo = _marketInfo;
        tokenPrices = _tokenPrices;
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
        }(tonWallet, userTip3Wallet, marketId, tokensToSupply, marketInfo[marketId].index);
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