pragma ton-solidity >= 0.47.0;

import './interfaces/IModule.sol';

contract WithdrawModule {
    address marketAddress;
    address userAccountManager;
    address owner;

    mapping (uint32 => MarketInfo) marketInfo;
    mapping (address => fraction) tokenPrices;

    constructor() public {
        tvm.accept();
    }

    function updateCache(address tonWallet, mapping(uint32 => MarketInfo) _marketInfo, mapping(address => fraction) _tokenPrices) external onlyMarket {
        marketInfo = _marketInfo;
        tokenPrices = _tokenPrices;
        tonWallet.transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    function performAction(uint32 marketId, TvmCell args) external view onlyMarket {
        TvmSlice ts = args.toSlice();
        (address tonWallet, address userTip3Wallet, address originalTip3Wallet, uint128 tokensToWithdraw, uint32 marketId) = ts.decode(address, address, address, uint128, uint32);
        mapping(uint32 => fraction) updatedIndexes = _createUpdatedIndexes();
        IUAMUserAccount(userAccountManager).requestWithdrawInfo{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, userTip3Wallet, originalTip3Wallet, uint256(tokensToWithdraw), marketId, updatedIndexes);
    }

    function _createUpdatedIndexes() internal returns(mapping(uint32 => fraction) updatedIndexes) {
        for ((uint32 marketId, MarketInfo mi): marketInfo) {
            updatedIndexes[marketId] = mi.index;
        }
    }

    function withdrawTokensFromMarket(
        address tonWallet, 
        address userTip3Wallet, 
        address originalTip3Wallet, 
        uint256 tokensToWithdraw, 
        uint32 marketId, 
        mapping(uint32 => uint256) si,
        mapping(uint32 => uint256) bi
    ) external view onlyMarket {
        MarketDelta marketDelta;

        fraction exchangeRate = MarketOperations.calculateExchangeRate({
            currentPoolBalance: marketInfo.currentPoolBalance,
            totalBorrowed: marketInfo.totalBorrowed,
            totalReserve: marketInfo.totalReserve,
            totalSupply: marketInfo.totalSupply
        });

        (uint256 supplySum, uint256 borrowSum) = _calculateBorrowSupplyDiff(si, bi);

        fraction fTokensToSend = tokensToWithdraw.fNumDiv(tokensToWithdraw);
        uint256 tokensToSend = fTokensToSend.toNum();
        if (supplySum > borrowSum) {
            if (supplySum - borrowSum > tokensToSend) {
                emit TokensWithdrawn(tonWallet, marketId, tokensToSend, markets[marketId]);

                marketDelta.currentPoolBalance.delta = tokensToSend;
                marketDelta.currentPoolBalance.positive = false;
                marketDelta.totalSupply.delta = tokensToSend;
                marketDelta.totalSupply.positive = false;

                IContractStateCacheRoot(marketAddress).uploadDelta{
                    value: 1 ton
                }(tonWallet, marketDelta);

                IUAMUserAccount(userAccountManager).writeWithdrawInfo{
                    flag: MsgFlag.REMAINING_GAS
                }(tonWallet, userTip3Wallet, marketId, tokensToWithdraw, tokensToSend);
            } else {
                IUAMUserAccount(userAccountManager).updateIndexesAndReturnTokens{
                    flag: MsgFlag.REMAINING_GAS
                }(tonWallet, originalTip3Wallet, marketId, tokensToWithdraw);
            }
        } else {
            IUAMUserAccount(userAccountManager).markForLiquidation{
                flag: MsgFlag.REMAINING_GAS
            }(tonWallet);
        }
    }

    modifier onlyMarket() {
        require(msg.sender == marketAddress);
        tvm.rawReserve(msg.value, 2);
        _;
    }
}