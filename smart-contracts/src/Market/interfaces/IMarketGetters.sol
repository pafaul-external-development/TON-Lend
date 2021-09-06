pragma ton-solidity >= 0.43.0;

import '../Structures.sol';

interface IMarketGetters {
    function getServiceContractAddresses() external view responsible returns (address, address, address);
    function getMarketInformation(uint32 marketId) external view responsible returns(MarketInfo);
    function getAllMarkets() external view responsible returns (mapping(uint32 => MarketInfo));
}