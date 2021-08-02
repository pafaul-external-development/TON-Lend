pragma ton-solidity >= 0.39.0;

interface IWalletControllerMarketManagement {
    function addMarket(address market, address realTokenRoot, address virtualTokenRoot) external;
    function removeMarket(address market) external;
}