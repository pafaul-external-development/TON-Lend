pragma ton-solidity >= 0.43.0;

library MarketOperations {
    uint8 constant SUPPLY_TOKENS = 0;
    uint8 constant WITHDRAW_TOKENS = 1;
    uint8 constant BORROW_TOKENS = 2;
    uint8 constant REPAY_LOAN = 3;
    uint8 constant LIQUIDATE_LOAN = 4;
}