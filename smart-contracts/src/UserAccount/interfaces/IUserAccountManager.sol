pragma ton-solidity >= 0.39.0;

interface IUserAccountManager {
    function createUserAccount(address tonWallet) external view;
    function calculateUserAccountAddress(address tonWallet) external responsible view returns (address);
}