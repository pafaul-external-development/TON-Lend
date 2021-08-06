pragma ton-solidity >= 0.39.0;

interface IMarket {
    function mintWrappedTokens(address userAccount, uint256 amount);
    function getInfo();  //TODO: возвращаемые значения
}