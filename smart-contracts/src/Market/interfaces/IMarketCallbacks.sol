pragma ton-solidity >= 0.43.0;

interface IMarketUAMCallbacks {
    function receiveInformationFromUser(address tonWallet, TvmCell payload) external;
}

interface IMarketTIP3WCCallbacks {

}