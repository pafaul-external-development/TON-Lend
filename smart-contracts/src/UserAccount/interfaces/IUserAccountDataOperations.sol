pragma ton-solidity >= 0.39.0;

interface IUserAccountDataOperations {
    function fetchInformationFromUserAccount(address tonWallet, TvmCell payload) external;
    function passInformationToMarket(address tonWallet, TvmCell payload) external;
    function writeInformationToUserAccount(address tonWallet, TvmCell payload) external;
}