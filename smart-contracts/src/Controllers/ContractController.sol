pragma ton-solidity >= 0.39.0;
pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "./interfaces/ICCCodeManager.sol";

import "./libraries/PlatformCodes.sol";

import "../utils/Platform/Platform.sol";
import "../utils/interfaces/IUpgradableContract.sol";


contract ContractController is IContractControllerCodeManager {
    mapping(uint8 => CodeStorage) contractCodes;

    // Contract code managing functions
    function addContractCode(uint8 contractType, TvmCell code, uint32 codeVersion, uint128 deployCost) override external contractTypeExists(contractType, false) {
        tvm.accept();
        contractCodes[contractType] = CodeStorage(code, codeVersion, deployCost);
    }

    function updateContractCode(uint8 contractType, TvmCell code, uint32 codeVersion) override external contractTypeExists(contractType, true) {
        tvm.accept();
        if (codeVersion > contractCodes[contractType].codeVersion) {
            contractCodes[contractType].code = code;
            contractCodes[contractType].codeVersion = codeVersion;
        }
    }

    function setContractDeployCost(uint8 contractType, uint128 deployCost) override external contractTypeExists(contractType, true) {
        tvm.accept();
        contractCodes[contractType].deployCost = deployCost;
    }

    function createContract(uint8 contractType, TvmCell initialData, TvmCell params) override external contractTypeExists(contractType, true) {
        require(msg.value >= contractCodes[contractType].deployCost);
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
        }(contractCodes[contractType].code, params, address(this));
    }

    function updateContract(uint8 contractType, address contractAddress, TvmCell updateParams) override external contractTypeExists(contractType, true) {
        tvm.accept();
        IUpgradableContract(contractAddress).upgradeContractCode{
            value: msg.value,
            bounce: true
        }(contractCodes[contractType].code, updateParams, contractCodes[contractType].codeVersion, contractType);
    }

    function getCodeVersion(uint8 contractType) override external responsible contractTypeExists(contractType, true) returns (uint32) {
        return { value: 0, bounce: false, flag: MsgFlag.REMAINING_GAS } contractCodes[contractType].codeVersion;
    }

    function getCodeStorage(uint8 contractType) override external responsible contractTypeExists(contractType, true) returns (CodeStorage) {
        return { value: 0, bounce: false, flag: MsgFlag.REMAINING_GAS } (contractCodes[contractType]);
    }

    // modifiers
    modifier contractTypeExists(uint8 contractType, bool exists) {
        require(contractCodes.exists(contractType) == exists);
        _;
    }
}