pragma ton-solidity >= 0.47.0;

import '../../Market/MarketInfo.sol';
import '../../Market/libraries/MarketOperations.sol';

import '../../UserAccount/interfaces/IUAMUserAccount.sol';

import '../../WalletController/libraries/OperationCodes.sol';

import '../../utils/interfaces/IUpgradableContract.sol';

import '../../utils/libraries/MsgFlag.sol';

interface IModule {
    function performAction(uint32 marketId, TvmCell args, mapping (uint32 => MarketInfo) _marketInfo, mapping (address => fraction) _tokenPrices) external;
    function resumeOperation(uint32 marketId, TvmCell args, mapping(uint32 => MarketInfo) _marketInfo, mapping (address => fraction) _tokenPrices) external;
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
    function receiveCacheDelta(uint32 marketId, MarketDelta marketDelta, TvmCell args) external;
}

interface ISupplyModule {

}

interface IWithdrawModule {
    function withdrawTokensFromMarket(
        address tonWallet, 
        address userTip3Wallet,
        uint256 tokensToWithdraw, 
        uint32 marketId, 
        mapping(uint32 => uint256) supplyInfo,
        mapping (uint32 => BorrowInfo) borrowInfo
    ) external;
}

interface IBorrowModule {
    function borrowTokensFromMarket(
        address tonWallet,
        address userTip3Wallet,
        uint256 tokensToBorrow,
        uint32 marketId,
        mapping (uint32 => uint256) supplyInfo,
        mapping (uint32 => BorrowInfo) borrowInfo
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

interface ILiquidationModule {
    
}

library Utilities {
    using UFO for uint256;
    using FPO for fraction;

    function calculateSupplyBorrow(
        mapping(uint32 => uint256) supplyInfo, 
        mapping(uint32 => uint256) borrowInfo, 
        mapping(uint32 => MarketInfo) marketInfo, 
        mapping(address => fraction) tokenPrices
    ) internal returns (uint256, uint256) {
        uint256 supplySum = 0;
        uint256 borrowSum = 0;
        fraction tmp;
        fraction exchangeRate;

        // Supply:
        // 1. Calculate real token amount: vToken*exchangeRate
        // 2. Calculate real token amount in USD: realTokens/tokenPrice
        // 3. Multiply by collateral factor: usdValue*collateralFactor
        for ((uint32 marketId, uint256 supplied): supplyInfo) {
            tmp = supplied.fNumMul(marketInfo[marketId].exchangeRate);
            tmp = tmp.fDiv(tokenPrices(marketInfo[marketId].token));
            tmp = tmp.fMul(marketInfo[marketId].collateralFactor);
            supplySum += tmp.toNum();
        }

        // Borrow:
        // 1. Recalculate amount of borrowed tokens (update index)
        // 2. Calculate borrow USD amount 
        for ((uint32 marketId, ): borrowInfo) {
            tmp = 
            borrowSum += tmp.toNum();
        }

        return (supplySum, borrowSum);
    }

    function calculateSupplyBorrowFull(
        mapping(uint32 => uint256) supplyInfo,
        mapping(uint32 => BorrowInfo) borrowInfo,
        mapping(uint32 => MarketInfo) marketInfo,
        mapping(address => fraction) tokenPrices
    ) internal returns (fraction) {
        // TODO: use calculateSupplyBorrowFull instead of calculteSupplyBorrow 
        // TODO: rename later
        fraction accountHealth = fraction(0, 0);
        fraction tmp;

        // Supply:
        // 1. Calculate real token amount: vToken*exchangeRate
        // 2. Calculate real token amount in USD: realTokens/tokenPrice
        // 3. Multiply by collateral factor: usdValue*collateralFactor
        for ((uint32 marketId, uint256 supplied): supplyInfo) {
            tmp = supplied.fNumMul(marketInfo[marketId].exchangeRate);
            tmp = tmp.fDiv(tokenPrices(marketInfo[marketId].token));
            tmp = tmp.fMul(marketInfo[marketId].collateralFactor);
            accountHealth.nom += tmp.toNum();
        }

        // Borrow:
        // 1. Recalculate borrow amount according to new index
        // 2. Calculate borrow value in USD
        // NOTE: no conversion from vToken to real tokens required, as value is stored in real tokens
        for ((uint32 marketId, BorrowInfo _bi): borrowInfo) {
            if (_bi.tokensBorrowed != 0) {
                if (!_bi.index.eq(marketInfo[marketId].index)) {
                    tmp = borrowInfo[marketId].tokensBorrowed.numFMul(marketInfo[marketId].index);
                    tmp = tmp.fDiv(borrowInfo[marketId].index);
                } else {
                    tmp = borrowInfo[marketId].tokensBorrowed.toF();
                }
                tmp = tmp.fMul(tokenPrices[marketInfo[marketId].token]);
                accountHealth.denom += tmp.toNum();
            }
        }

        return accountHealth;
    }
}