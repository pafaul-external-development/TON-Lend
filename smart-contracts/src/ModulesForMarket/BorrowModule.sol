pragma ton-solidity 0.47.0;

import './interfaces/IModule.sol';

contract BorrowModule {
    using FPO for fraction;
    using UFO for uint256;

    address marketAddress;
    address userAccountManager;

    constructor() public {
        tvm.accept();
    }

    function borrowTokensFromMarket(
        address tonWallet,
        address userTip3Wallet,
        uint256 tokensToBorrow,
        uint32 marketId,
        mapping (uint32 => MarketInfo) marketInfo,
        mapping (uint32 => uint256) bi,
        mapping (uint32 => uint256) si,
        mapping (address => fraction) tokenPrices
    ) external view onlyMarket {
        MarketInfo marketDelta;
        (uint256 supplySum, uint256 borrowSum) = Utilities.calculateSupplyBorrow(si, bi, marketInfo, tokenPrices);

        if (borrowSum < supplySum) {
            uint256 tmp_ = supplySum - borrowSum;
            fraction tmp = tmp_.numFDiv(tokenPrices[marketInfo[marketId].token]);
            if (tmp_ >= tokensToBorrow) {
                marketDelta.totalBorrowed = tokensToBorrow;

                IUAMUserAccount(userAccountManager).writeBorrowInformation{
                    flag: MsgFlag.REMAINING_GAS
                }(tonWallet, userTip3Wallet, tokensToBorrow, marketId, marketDelta);
            } else {
                address(tonWallet).transfer({
                    value: 0,
                    flag: MsgFlag.REMAINING_GAS
                });
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