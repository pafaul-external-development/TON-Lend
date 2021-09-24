pragma ton-solidity >= 0.47.0;

import './interfaces/IModule.sol';

contract SupplyModule is IModule, IContractStateCache {

    address marketAddress;
    address userAccountManager;

    mapping (uint32=>MarketInfo) marketInfo;
    mapping (address => fraction) tokenPrices;
    
    constructor() public {
        tvm.accept();
    }

    function supplyTokensToMarkets(address tonWallet, address userTip3Wallet, uint128 tokenAmount, uint32 marketId) external onlyMarket {
        (uint256 tokensToSupply, MarketInfo marketDelta) = SupplyTokensLib.calculateSupply(tokenAmount, marketInfo);
        IUAMUserAccount(userAccountManager).writeSupplyInfo{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, userTip3Wallet, marketId, tokensToSupply, marketId, marketInfo);
    }

    function receiveResponse(address tonWallet, address userTip3Wallet, uint256 tokensSupplied) external onlyUserAccountManager {
        MarketInfo delta;
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