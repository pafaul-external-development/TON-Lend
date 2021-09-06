pragma ton-solidity >= 0.39.0;

interface IUserAccountData {
    function fetchInformationFromUserAccount(TvmCell payload) external responsible returns(address, TvmCell);
    function writeInformationToUserAccount(TvmCell payload) external;
}