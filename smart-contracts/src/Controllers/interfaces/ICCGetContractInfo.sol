pragma ton-solidity >= 0.39.0;
pragma AbiHeader time;
pragma AbiHeader expire;

interface IContractControllerGetContractInfo {
    function getContractAddresses(uint8 contractType) external returns (address[]);
    function getContractType(address contractAddress) external returns (uint8);

    function getCodeVersion(uint8 contractType) external responsible returns (uint32);
    function getCodeStorage(uint8 contractType) external responsible returns (CodeStorage);
}