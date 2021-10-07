pragma ton-solidity >= 0.39.0;

library OperationCodes {
    uint8 constant SUPPLY_TOKENS = 0;
    uint8 constant REPAY_TOKENS = 1;
    uint8 constant WITHDRAW_TOKENS = 2;
    uint8 constant BORROW_TOKENS = 3;
    uint8 constant NO_OP = 255;
}