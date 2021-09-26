pragma ton-solidity >= 0.47.0;

import './interfaces/IModule.sol';

contract RepayModule is IModule {
    address userAccountManager;
    address marketAddress;
    address owner;

    mapping(uint32 => MarketInfo) marketInfo;
    mapping(address => fraction) tokenPrices;


    constructor(address _userAccountManager, address _marketAddress, address _owner) public {
        tvm.accept();
        userAccountManager = _userAccountManager;
        marketAddress = _marketAddress;
        owner = _owner;
    }

    function updateCache(address tonWallet, mapping(uint32 => MarketInfo) _marketInfo, mapping(address => fraction) _tokenPrices) external onlyMarket {
        marketInfo = _marketInfo;
        tokenPrices = _tokenPrices;
        tonWallet.transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    function performAction(uint32 marketId, TvmCell args) external onlyMarket {
        (address tonWallet, address tip3UserWallet, uint256 tokensReceived, uint32 marketId, uint8 loanId) = args.decode(address, address, uint256, uint32, uint8);
        mapping(uint32 => fraction) updatedIndexes = _createUpdatedIndexes();

        IUAMUserAccount(userAccountManager).receiveRepayInfo{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, tip3UserWallet, tokensReceived, marketId, loanId, updatedIndexes);
    }

    function _createUpdatedIndexes() internal returns(mapping(uint32 => fraction) updatedIndexes) {
        for ((uint32 marketId, MarketInfo mi): marketInfo) {
            updatedIndexes[marketId] = mi.index;
        }
    }

    function repayLoan(
        address tonWallet,
        address tip3UserWallet,
        uint256 tokensReceived,
        uint32 marketId,
        uint8 loanId,
        BorrowInfo borrowInfo,
        mapping(uint32 => uint256) si,
        mapping(uint32 => uint256) bi
    ) external onlyUserAccountManager {
        (uint256 supplySum, uint256 borrowSum) = Utilities.calculateSupplyBorrow(si, bi, marketInfo, tokenPrices);
        if (supplySum > borrowSum) {
            MarketDelta marketDelta;

            fraction newRepayInfo = marketInfo[marketId].index.fNumMul(borrowInfo.toRepay);
            newRepayInfo = newRepayInfo.fDiv(borrowInfo.index);
            uint256 tokensToRepay = newRepayInfo.toNum();
            uint256 tokensToReturn;
            if (tokensToRepay <= tokensForRepay) {
                tokensToReturn = tokensForRepay - tokensToRepay;
                borrowInfo.toRepay = 0;
                marketDelta.totalBorrowed = -tokensToRepay;
                marketDelta.currentPoolBalance = tokensToRepay;
                emit TokensRepayed(tonWallet, marketId, tokensToRepay, tokensToRepay, marketInfo[marketId]);
            } else {
                tokensToReturn = 0;
                borrowInfo.toRepay = tokensToRepay - tokensForRepay;
                borrowInfo.index = marketInfo[marketId].index;
                marketDelta.totalBorrowed = -tokensForRepay;
                marketDelta.currentPoolBalance = tokensForRepay;
                emit TokensRepayed(tonWallet, marketId, tokensToRepay, tokensForRepay, marketInfo[marketId]);
            } 

            IContractStateCacheRoot(marketAddress).uploadDelta{
                value: 1 ton
            }(tonWallet, marketDelta);

            IUAMUserAccount(userAccountManager).writeRepayInformation{
                flag: MsgFlag.REMAINING_GAS
            }(tonWallet, userTip3Wallet, marketId, loanId, tokensToReturn, borrowInfo);
        } else {
            IUAMUserAccount(userAccountManager).markForLiquidation{
                flag: MsgFlag.REMAINING_GAS
            }(tonWallet);
        }
    }

    modifier onlyMarket() {
        require(msg.sender == marketAddress);
        _;
    }

    modifier onlyUserAccountManager() {
        require(msg.sender == userAccountManager);
        _;
    }
}