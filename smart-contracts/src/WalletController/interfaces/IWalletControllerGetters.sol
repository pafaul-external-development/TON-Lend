pragma ton-solidity >= 0.43.0;

struct MarketTokenAddresses {
    address realToken;
    address virtualToken;
    address realTokenWallet;
    address virtualTokenWallet;
}

interface IWalletControllerGetters {
    function getRealTokenRoots() external view responsible returns(mapping(address => bool));
    function getVirtualTokenRoots() external view responsible returns(mapping(address => bool));
    function getWallets() external view responsible returns(mapping(address => address));
    function getMarketAddresses(uint32 marketId) external view responsible returns(MarketTokenAddresses);
    function getAllMarkets() external view responsible returns(mapping(uint32 => MarketTokenAddresses));
}