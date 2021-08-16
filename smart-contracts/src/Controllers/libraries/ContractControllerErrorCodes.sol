pragma ton-solidity >= 0.39.0;

library ContractControllerErrorCodes {
    uint8 constant ERROR_MSG_SENDER_IS_NOT_SELF = 100;
    uint8 constant ERROR_MSG_SENDER_IS_NOT_ROOT = 101;
    uint8 constant ERROR_MSG_SENDER_IS_NOT_KNOWN = 102;
    uint8 constant ERROR_MSG_SENDER_IS_NOT_CREATOR = 103;

    uint8 constant ERROR_CONTRACT_TYPE_ALREADY_EXISTS = 110;
    uint8 constant ERROR_CONTRACT_TYPE_DOES_NOT_EXIST = 111;
    uint8 constant ERROR_CONTRACT_TYPE_IS_INVALID     = 112;

    uint8 constant ERROR_MSG_VALUE_LOW = 120;

    uint8 constant ERROR_CODE_VERSION_IS_NOT_UPDATED = 130;
}