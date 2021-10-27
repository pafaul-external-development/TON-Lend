pragma ton-solidity >= 0.39.0;

interface IUserAccountManager {
    function createUserAccount(address tonWallet) external view responsible returns(address);
    function calculateUserAccountAddress(address tonWallet) external responsible view returns (address);

    function uploadUserAccountCode(uint32 version, TvmCell code) external;
    function updateUserAccount(address tonWallet) external;
    function getUserAccountCode(uint32 version) external view responsible returns(TvmCell);
}