pragma ton-solidity >= 0.39.0;

interface ITIP3ControllerMarketManagement {
    function addMarket(address market, address realTokenRoot, address virtualTokenRoot) external;
    function removeMarket(address market) external;
}