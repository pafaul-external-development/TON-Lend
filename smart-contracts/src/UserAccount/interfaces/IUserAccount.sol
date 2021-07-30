pragma ton-solidity >= 0.39.0;

interface IUserAccount {
    function getOwner() external responsible view returns(address);

    function enterMarket(address market) external responsible view returns(address);
}