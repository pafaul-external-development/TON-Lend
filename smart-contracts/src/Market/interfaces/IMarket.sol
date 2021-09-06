pragma ton-solidity >= 0.39.0;


import "../Structures.sol";


interface IMarket {
    function mintWrappedTokens(address userAccount, uint256 amount);
    function getInfo() external view responsible returns (MarketInfo);
}