pragma ton-solidity >= 0.39.0;

library ContractControllerErrorCodes {
    uint8 constant ERROR_UNAUTHORIZED_ACCESS = 100;
    uint8 constant ERROR_CONTRACT_TYPE_ALREADY_EXISTS = 110;
    uint8 constant ERROR_CONTRACT_TYPE_DOES_NOT_EXIST = 111;
    uint8 constant ERROR_MSG_VALUE_LOW = 120;
}