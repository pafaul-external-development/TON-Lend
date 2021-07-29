pragma ton-solc ^0.39.0;
pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

interface IOracleReturnPrices {
    function getMarketPrice(address market, TvmCell payload) virtual external view returns (uint256 priceToUSD, TvmCell payload);
    function getAllMarketsPrices(TvmCell payload) virtual external view returns (mapping(address => MarketPriceInfo) prices, TvmCell payload);
}