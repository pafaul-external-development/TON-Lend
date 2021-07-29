pragma ton-solc ^0.39.0;
pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

interface IContractControllerCodeManager {
    struct CodeStorage {
        TvmCell code;
        uint32 codeVersion;
        uint128 deployCost;
    }
    
    function addContractCode(uint8 contractType, TvmCell code, uint32 codeVersion, uint128 deployCost) virtual external;
    function createContract(uint8 contractType, TvmCell initialData, TvmCell params) virtual external;
    function updateContractCode(uint8 contractType, TvmCell code, uint32 codeVersion) virtual external;
    function updateContract(uint8 contractType, address contractAddress, TvmCell updateParams) virtual external;

    function getCodeVersion(uint8 contractType) virtual external responsible returns (uint32);
    function getCodeStorage(uint8 contractType) virtual external responsible returns (CodeStorage);

    function setContractDeployCost(uint8 contractType, uint128 deployCost) virtual external;
}