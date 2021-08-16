pragma ton-solidity >= 0.39.0;

library MarketErrorCodes {
    uint8 constant ERROR_MSG_SENDER_IS_NOT_SELF = 100;
    uint8 constant ERROR_MSG_SENDER_IS_NOT_ROOT = 101;
    uint8 constant ERROR_MSG_SENDER_IS_NOT_REAL_TOKEN = 102;
    uint8 constant ERROR_MSG_SENDER_IS_NOT_VIRTUAL_TOKEN = 103;
    uint8 constant ERROR_MSG_SENDER_IS_NOT_TIP3_DEPLOYER = 104;
    uint8 constant ERROR_INVALID_CONTRACT_TYPE = 200;
}
