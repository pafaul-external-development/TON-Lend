pragma ton-solidity >= 0.39.0;

interface IUserAccountManager {
    function createUserAccount(address tonWallet) external responsible view returns (address);

    function calculateUserAccountAddress(address tonWallet) external responsible view returns (address);
}