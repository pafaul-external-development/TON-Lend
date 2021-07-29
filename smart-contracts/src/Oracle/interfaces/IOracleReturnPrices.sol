pragma ton-solidity >= 0.39.0;
pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "./IOracleUpdatePrices.sol";

interface IOracleReturnPrices {
    function getMarketPrice(address market, TvmCell payload) external responsible view returns (uint256, TvmCell);
    function getAllMarketsPrices(TvmCell payload) external responsible view returns (mapping(address => MarketPriceInfo), TvmCell);
}