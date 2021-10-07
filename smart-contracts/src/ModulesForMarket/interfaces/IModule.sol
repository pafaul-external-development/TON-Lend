pragma ton-solidity >= 0.47.0;

import '../../Market/MarketInfo.sol';
import '../../Market/libraries/MarketOperations.sol';

import '../../UserAccount/interfaces/IUAMUserAccount.sol';

import '../../WalletController/libraries/OperationCodes.sol';

import '../../utils/interfaces/IUpgradableContract.sol';

import '../../utils/libraries/MsgFlag.sol';

import '../../Market/interfaces/IMarketInterfaces.sol';

interface IModule {
    function performAction(uint32 marketId, TvmCell args, mapping (uint32 => MarketInfo) _marketInfo, mapping (address => fraction) _tokenPrices) external;
    function sendActionId() external view responsible returns(uint8);
    function getModuleState() external view returns (mapping (uint32 => MarketInfo) _marketInfo, mapping (address => fraction) _tokenPrices);
}

interface IContractAddressSG {
    function setMarketAddress(address _marketAddress) external;
    function setUserAccountManager(address _userAccountManager) external;
    function getContractAddresses() external view responsible returns(address _owner, address _marketAddress, address _userAccountManager);
}

interface IContractStateCache {
    function updateCache(address tonWallet, mapping (uint32 => MarketInfo) _marketInfo, mapping (address => fraction) _tokenPrices) external;
}

interface IContractStateCacheRoot {
    function receiveCacheDelta(address tonWallet, MarketDelta marketDelta, uint32 marketId) external;
}

interface ISupplyModule {

}

interface IWithdrawModule {
    function withdrawTokensFromMarket(
        address tonWallet, 
        address userTip3Wallet,
        uint256 tokensToWithdraw, 
        uint32 marketId, 
        mapping(uint32 => uint256) si,
        mapping(uint32 => uint256) bi
    ) external;
}

interface IBorrowModule {
    function borrowTokensFromMarket(
        address tonWallet,
        address userTip3Wallet,
        uint256 tokensToBorrow,
        uint32 marketId,
        mapping (uint32 => uint256) si,
        mapping (uint32 => uint256) bi
    ) external;
}

interface IRepayModule {
    function repayLoan(
        address tonWallet,
        address userTip3Wallet,
        uint256 tokensForRepay,
        uint32 marketId,
        BorrowInfo borrowInfo
    ) external view;
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
            exchangeRate = marketInfo[marketId].exchangeRate;
            tmp = exchangeRate.fNumMul(si[marketId]);
            tmp = tmp.fMul(tokenPrices[marketInfo[marketId].token]);
            tmp = tmp.fMul(marketInfo[marketId].collateralFactor);
            supplySum += tmp.toNum();

            tmp = exchangeRate.fNumMul(bi[marketId]);
            tmp = tmp.fMul(tokenPrices[marketInfo[marketId].token]);
            borrowSum += tmp.toNum();
        }

        return (supplySum, borrowSum);
    }
}