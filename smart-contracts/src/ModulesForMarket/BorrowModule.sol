pragma ton-solidity >= 0.47.0;

import './interfaces/IModule.sol';

import '../utils/libraries/MsgFlag.sol';

contract BorrowModule is IContractStateCache {
    using FPO for fraction;
    using UFO for uint256;

    address marketAddress;
    address userAccountManager;

    mapping (uint32 => MarketInfo) marketInfo;
    mapping (address => fraction) tokenPrices;

    constructor() public {
        tvm.accept();
    }

    function updateCache(address tonWallet, mapping (uint32 => MarketInfo) marketInfo_, mapping (address => fraction) tokenPrices_) external override onlyMarket {
        marketInfo = marketInfo_;
        tokenPrices = tokenPrices_;
        tonWallet.transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    function performAction(uint32 marketId, TvmCell args) external onlyMarket {
        TvmSlice ts = args.toSlice();
        (address tonWallet, address userTip3Wallet, uint256 tokensToBorrow) = ts.decode(address, address, uint256);
        mapping(uint32 => fraction) updatedIndexes = _createUpdatedIndexes();
        IUAMUserAccount(userAccountManager).updateUserIndexes{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, userTip3Wallet, tokensToBorrow, marketId, updatedIndexes);
    }

    function _createUpdatedIndexes() internal view returns(mapping(uint32 => fraction) updatedIndexes) {
        for ((uint32 marketId, MarketInfo mi): marketInfo) {
            updatedIndexes[marketId] = mi.index;
        }
    }

    function borrowTokensFromMarket(
        address tonWallet,
        address userTip3Wallet,
        uint256 tokensToBorrow,
        uint32 marketId,
        mapping (uint32 => uint256) si,
        mapping (uint32 => uint256) bi
    ) external onlyMarket {
        MarketDelta marketDelta;
        (uint256 supplySum, uint256 borrowSum) = Utilities.calculateSupplyBorrow(si, bi, marketInfo, tokenPrices);

        if (borrowSum < supplySum) {
            uint256 tmp_ = supplySum - borrowSum;
            fraction tmp = tmp_.numFDiv(tokenPrices[marketInfo[marketId].token]);
            tmp_ = tmp.toNum();
            if (tmp_ >= tokensToBorrow) {
                marketDelta.totalBorrowed.delta = tokensToBorrow;
                marketDelta.totalBorrowed.positive = true;
                marketDelta.currentPoolBalance.delta = tokensToBorrow;
                marketDelta.currentPoolBalance.positive = false;

                IContractStateCacheRoot(marketAddress).receiveCacheDelta{
                    value: 1 ton
                }(tonWallet, marketDelta);

                IUAMUserAccount(userAccountManager).writeBorrowInformation{
                    flag: MsgFlag.REMAINING_GAS
                }(tonWallet, userTip3Wallet, tokensToBorrow, marketId, marketInfo[marketId].index);
            } else {
                IUAMUserAccount(userAccountManager).writeBorrowInformation{
                    flag: MsgFlag.REMAINING_GAS
                }(tonWallet, userTip3Wallet, 0, marketId, marketInfo[marketId].index);
            }
        } else {
            // TODO: notify market to mark account for liquidation
        }
    }

    modifier onlyMarket() {
        require(msg.sender == marketAddress);
        tvm.rawReserve(msg.value, 2);
        _;
    }
}