pragma ton-solidity >= 0.47.0;

import './interfaces/IModule.sol';

contract SupplyModule is IModule, IContractStateCache {

    address marketAddress;
    address userAccountManager;

    mapping (uint32 => MarketInfo) marketInfo;
    mapping (address => fraction) tokenPrices;
    
    constructor() public {
        tvm.accept();
    }

    function updateCache(address tonWallet, mapping (uint32 => MarketInfo) marketInfo_, mapping (address => uint256) tokenPrices_) external onlyMarket {
        marketInfo = marketInfo_;
        tokenPrices = tokenPrices_;
        tonWallet.transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    function supplyTokensToMarkets(address tonWallet, address userTip3Wallet, uint128 tokenAmount, uint32 marketId) external onlyMarket {
        (uint256 tokensToSupply, MarketInfo marketDelta) = SupplyTokensLib.calculateSupply(tokenAmount, marketInfo);
        MarketInfo delta;
        delta.currentPoolBalance = tokenAmount;
        delta.totalSupply = tokenAmount;
        IMarketUpdateCache(marketAddress).updateCache{
            value: 1 ton
        }(delta);

        IUAMUserAccount(userAccountManager).writeSupplyInfo{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, userTip3Wallet, marketId, tokensToSupply, tokenAmount);
    }

    function receiveResponse(address tonWallet, address userTip3Wallet, uint256 tokensSupplied) external onlyUserAccountManager {
        MarketInfo delta;
        delta.totalSupply = tokensSupplied;
        IMarketSupply(marketAddress).tokensSupplied{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, userTip3Wallet, tokensSupplied, marketInfo);
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
}