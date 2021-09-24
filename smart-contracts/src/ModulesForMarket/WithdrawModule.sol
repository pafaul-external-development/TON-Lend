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

        fraction toPayout = fraction (0, 0);
    }

    modifier onlyMarket() {
        require(msg.sender == marketAddress);
        tvm.rawReserve(msg.value, 2);
        _;
    }
}