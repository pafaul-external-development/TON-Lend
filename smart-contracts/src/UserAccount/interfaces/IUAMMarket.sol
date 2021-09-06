pragma ton-solidity >= 0.39.0;

interface IUAMMarket {
    function setMarketAddress(address market_) external;
    function addMarket(uint32 marketId) external;
    function removeMarket(uint32 marketId) external;
}