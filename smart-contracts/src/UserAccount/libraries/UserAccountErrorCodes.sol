pragma ton-solidity >= 0.39.0;

library UserAccountErrorCodes {
    uint8 constant ERROR_NOT_ROOT = 102;

    uint8 constant ERROR_INVALID_CONTRACT_TYPE = 200;
    
    // TODO: изменить номера ошибок
    uint8 constant ERROR_NOT_APPROVED_MARKET = 104; 
    uint8 constant ERROR_NOT_ENTERED_MARKETc = 105;
}