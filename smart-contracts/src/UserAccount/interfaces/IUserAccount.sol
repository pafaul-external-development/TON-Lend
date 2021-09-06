pragma ton-solidity >= 0.39.0;

interface IUserAccount {
    function getOwner() external responsible view returns(address);

    function enterMarket(uint32 marketId) external;
}