pragma ton-solidity >= 0.39.0;

interface IUAMMarket {
    function setMarketAddress(address market_) external;
    function addModule(uint8 operationId, address module) external;
    function removeModule(uint8 operationId) external;
}