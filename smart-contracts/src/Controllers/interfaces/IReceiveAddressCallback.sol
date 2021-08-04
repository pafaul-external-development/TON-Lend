pragma ton-solidity >= 0.39.0;

interface IReceiveAddressCallback {
    function getDeployedAddressCallback(address deployedContractAddress) external;
}