pragma ton-solidity >= 0.39.0;
pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

interface IContractControllerCodeManager {
    
    function addContractCode(uint8 contractType, TvmCell code, uint32 codeVersion, uint128 deployCost) external;
    function createContract(uint8 contractType, TvmCell initialData, TvmCell params) external;
    function updateContractCode(uint8 contractType, TvmCell code, uint32 codeVersion) external;
    function updateContract(uint8 contractType, address contractAddress, TvmCell updateParams) external;
    function updateContracts(uint8 contractType, TvmCell updateParams) external;

    function calculateFutureAddress(uint8 contractType, TvmCell initialData) external responsible returns (address);

    function setContractDeployCost(uint8 contractType, uint128 deployCost) external;
}