pragma ton-solidity >= 0.47.0;

import './interfaces/IModule.sol';

contract WithdrawModule {
    address marketAddress;

    constructor() public {
        tvm.accept();
    }

    function withdrawTokensFromMarket(address tonWallet, address userTip3Wallet, uint256 tokensToWithdraw, uint32 marketId, MarketInfo marketInfo) external view onlyMarket {
        fraction exchangeRate = MarketOperations.calculateExchangeRate({
            currentPoolBalance: marketInfo.currentPoolBalance,
            totalBorrowed: marketInfo.totalBorrowed,
            totalReserve: marketInfo.totalReserve,
            totalSupply: marketInfo.totalSupply
        });

        (uint256 supplySum, uint256 borrowSum) = _calculateBorrowSupplyDiff(si, bi);
        mapping(uint32 => fraction) updatedIndexes = _createUpdatedIndexes(bi);

        if (supplySum > borrowSum) {
            if (supplySum - borrowSum > tokensToSend) {
                emit TokensWithdrawn(tonWallet, marketId, tokensToSend, markets[marketId]);

                IUAMUserAccount(userAccountManager).writeWithdrawInfo{
                    flag: MsgFlag.REMAINING_GAS
                }(tonWallet, userTip3Wallet, marketId, tokensToWithdraw, tokensToSend, updatedIndexes);
            } else {
                IUAMUserAccount(userAccountManager).updateIndexesAndReturnTokens{
                    flag: MsgFlag.REMAINING_GAS
                }(tonWallet, originalTip3Wallet, marketId, tokensToWithdraw, updatedIndexes);
            }
        } else {
            // TODO: mark for liquidation and transfer tokens back
        }
    }

    modifier onlyMarket() {
        require(msg.sender == marketAddress);
        tvm.rawReserve(msg.value, 2);
        _;
    }
}