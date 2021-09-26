pragma ton-solidity >= 0.47.0;

import '../../Market/MarketInfo.sol';
import '../../Market/libraries/MarketOperations.sol';

import '../../UserAccount/interfaces/IUAMUserAccount.sol';

interface IModule {
    function performAction(uint32 marketId, TvmCell args) external;
    function sendActionId() external view responsible returns(uint8);
}

interface IContractStateCache {
    function updateCache(address tonWallet, mapping (uint32 => MarketInfo) marketInfo_, mapping (address => fraction) tokenPrices_) external;
}

interface IContractStateCacheRoot {
    function receiveCacheDelta(address tonWallet, MarketDelta marketDelta) external;
}


library SupplyTokensLib {
    using UFO for uint256;
    using FPO for fraction;

    function calculateSupply(uint128 tokenAmount, MarketInfo marketInfo) internal returns(uint256) {
        uint256 tokensProvided = uint256(tokenAmount);
        fraction exchangeRate = MarketOperations.calculateExchangeRate({
            currentPoolBalance: marketInfo.currentPoolBalance,
            totalBorrowed: marketInfo.totalBorrowed,
            totalReserve: marketInfo.totalReserve,
            totalSupply: marketInfo.totalSupply
        });

        fraction fTokensToSupply = tokensProvided.numFDiv(exchangeRate);
        uint256 tokensToSupply = fTokensToSupply.toNum();

        return (tokensToSupply);
    }
}

library Utilities {
    using UFO for uint256;
    using FPO for fraction;

    function calculateSupplyBorrow(
        mapping(uint32 => uint256) si, 
        mapping(uint32 => uint256) bi, 
        mapping(uint32 => MarketInfo) marketInfo, 
        mapping(address => fraction) tokenPrices
    ) internal returns (uint256, uint256) {
        uint256 supplySum = 0;
        uint256 borrowSum = 0;
        fraction tmp;
        fraction exchangeRate;

        // For supply:
        // 1. Calculate real tokens
        // 2. Calculate real tokens cost in usd
        // 3. Multiply by collateral factor

        // For borrow:
        // 1. Calculate real tokens
        // 2. Calculate real tokens cost in usd
        for ((uint32 marketId, ): si) {
            exchangeRate = MarketOperations.calculateExchangeRate({
                currentPoolBalance: marketInfo[marketId].currentPoolBalance,
                totalBorrowed:  marketInfo[marketId].totalBorrowed,
                totalReserve: marketInfo[marketId].totalReserve,
                totalSupply: marketInfo[marketId].totalSupply
            });
            tmp = exchangeRate.fNumMul(si[marketId]);
            tmp = tmp.fMul(tokenPrices[marketInfo[marketId].token]);
            tmp = tmp.fMul(marketInfo[marketId].collateral);
            supplySum += tmp.toNum();

            tmp = exchangeRate.fNumMul(bi[marketId]);
            tmp = tmp.fMul(tokenPrices[marketInfo[marketId].token]);
            borrowSum += tmp.toNum();
        }

        return (supplySum, borrowSum);
    }
}