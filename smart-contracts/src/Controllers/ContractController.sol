pragma ton-solidity >= 0.39.0;
pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "./interfaces/ICCCodeManager.sol";

import "./libraries/PlatformCodes.sol";
import "./libraries/ContractControllerErrorCodes.sol";

import "../utils/Platform/Platform.sol";
import "../utils/interfaces/IUpgradableContract.sol";


contract ContractController is IContractControllerCodeManager, IUpgradableContract {

    uint8 contractType;
    uint256 ownerPubkey; // TODO: owner pubkey is for tests, will be removed
    address ownerAddress;

    mapping(uint8 => CodeStorage) contractCodes;

<<<<<<< HEAD
    // TODO: tmp solution
    constructor() public {
        tvm.accept();
    }

=======
    // Contract is deployed as regular contract
    constructor() public {
        tvm.accept();
        contractType = PlatformCodes.CONTRACT_CONTROLLER;
    }

    // From version 0 to version 1
    function upgradeContractCode(TvmCell code, TvmCell updateParams, uint32 codeVersion_, uint8 contractType_) override external correctContractType(contractType_) {

    }

    // From version 0 to version 1
    function onCodeUpgrade(TvmCell data) private {

    }

    /*********************************************************************************************************/
>>>>>>> b0f5c04f5d246eed3e8e2feb190e302ab60e74e2
    // Contract code managing functions
    /**
     * @param contractType Type of contract (check libraries/PlatfromCodes.sol)
     * @param code Contract code
     * @param codeVersion Version of contract code
     * @param deployCost Cost of deploying contract in nanotons
     */
    function addContractCode(uint8 contractType, TvmCell code, uint32 codeVersion, uint128 deployCost) override external contractTypeExists(contractType, false) {
        tvm.accept();
        contractCodes[contractType] = CodeStorage(code, codeVersion, deployCost);
    }

    /**
     * @param contractType Type of contract
     * @param code Updated contract code
     * @param codeVersion New code version
     */
    function updateContractCode(uint8 contractType, TvmCell code, uint32 codeVersion) override external contractTypeExists(contractType, true) {
        tvm.accept();
        if (codeVersion > contractCodes[contractType].codeVersion) {
            contractCodes[contractType].code = code;
            contractCodes[contractType].codeVersion = codeVersion;
        }
    }

    /**
     * @param contractType Type of contract
     * @param deployCost Cost of deploying contract in nanotons
     */
    function setContractDeployCost(uint8 contractType, uint128 deployCost) override external contractTypeExists(contractType, true) {
        tvm.accept();
        contractCodes[contractType].deployCost = deployCost;
    }

    /**
     * @param contractType Type of contract
     * @param initialData InitialData for deployed smart contract
     * @param params Parameters for smart contract deployment
     */
    function createContract(uint8 contractType, TvmCell initialData, TvmCell params) override external responsible contractTypeExists(contractType, true) returns (address) {
        require(msg.value >= contractCodes[contractType].deployCost, ContractControllerErrorCodes.ERROR_MSG_VALUE_LOW);
        tvm.accept();
        address newContract = new Platform{
            varInit: {
                root: address(this),
                platformType: contractType,
                platformCode: contractCodes[PlatformCodes.PLATFORM].code,
                initialData: initialData
            },
            value: contractCodes[contractType].deployCost,
            code: contractCodes[PlatformCodes.PLATFORM].code
        }(contractCodes[contractType].code, params);
        return { value: 0, bounce: false, flag: MsgFlag.REMAINING_GAS } newContract;
    }

    /**
     * @param contractType Type of contract
     * @param contractAddress Address of smart contract to update
     * @param updateParams Parameters required for update
     */
    function updateContract(uint8 contractType, address contractAddress, TvmCell updateParams) override external contractTypeExists(contractType, true) {
        tvm.accept();
        IUpgradableContract(contractAddress).upgradeContractCode{
            value: msg.value,
            bounce: true
        }(contractCodes[contractType].code, updateParams, contractCodes[contractType].codeVersion, contractType);
    }

    /*********************************************************************************************************/
    // Getters, for local execution
    /**
     * @param contractType Type of contract
     */
    function getCodeVersion(uint8 contractType) override external responsible contractTypeExists(contractType, true) returns (uint32) {
        return { value: 0, bounce: false, flag: MsgFlag.REMAINING_GAS } contractCodes[contractType].codeVersion;
    }

    /**
     * @param contractType Type of contract
     */
    function getCodeStorage(uint8 contractType) override external responsible contractTypeExists(contractType, true) returns (CodeStorage) {
        return { value: 0, bounce: false, flag: MsgFlag.REMAINING_GAS } (contractCodes[contractType]);
    }

    /**
     * @param contractType Type of contract
     * @param intialData Initial data used for contract
     */
    function calculateFutureAddress(uint8 contractType, TvmCell initialData) override external responsible returns (address) {
        return { value: 0, bounce: false, flag: MsgFlag.REMAINING_GAS } address(tvm.hash(_buildInitialData(contractType, initialData)));
    }

    /**
     * @param contractType Type of contract
     * @param initialData Initail data used for contract
     */
    function _buildInitialData(uint8 contractType, TvmCell initialData) private view returns (TvmCell) {
        return tvm.buildStateInit({
            contr: Platform,
            varInit: {
                root: address(this),
                platformType: contractType,
                platformCode: contractCodes[PlatformCodes.PLATFORM].code,
                initialData: initialData
            },
            pubkey: 0,
            code: contractCodes[PlatformCodes.PLATFORM].code
        });
    }

    /*********************************************************************************************************/
    // modifiers
    /**
     * @param contractType Type of contract
     * @param exists Does contractType exist in contractCodes mapping
     */
    modifier contractTypeExists(uint8 contractType, bool exists) {
        require(contractCodes.exists(contractType) == exists, exists == true? ContractControllerErrorCodes.ERROR_CONTRACT_TYPE_DOES_NOT_EXIST : ContractControllerErrorCodes.ERROR_CONTRACT_TYPE_ALREADY_EXISTS);
        _;
    }
}