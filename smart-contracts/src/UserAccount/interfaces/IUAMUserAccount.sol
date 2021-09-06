pragma ton-solidity >= 0.43.0;

interface IUAMUserAccount {
    function enterMarket(address tonWallet, uint32 marketId) external view responsible returns (address);
    function fetchInformationFromUserAccount(address tonWallet, TvmCell payload) external view;
    function passInformationToMarket(address tonWallet, TvmCell payload) external view;
    function writeInformationToUserAccount(address tonWallet, TvmCell payload) external view;
}