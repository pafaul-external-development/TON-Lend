pragma ton-solidity >= 0.39.0;
pragma AbiHeader time;
pragma AbiHeader expire;

interface IContractControllerGetContractInfo {
    struct CodeStorage {
        TvmCell code;
        uint32 codeVersion;
        uint128 deployCost;
    }

    function getContractAddresses(uint8 contractType) external responsible returns (address[]);
    function getContractType(address contractAddress) external responsible returns (uint8);

    function getCodeVersion(uint8 contractType) external responsible returns (uint32);
    function getCodeStorage(uint8 contractType) external responsible returns (CodeStorage);
}