pragma ton-solidity >= 0.39.0;
pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "./interfaces/ICCCodeManager.sol";
import "./interfaces/ICCRunLocal.sol";
import "./interfaces/ICCMarketDeployed.sol";
import "./interfaces/ICCGetContractInfo.sol";

import "./libraries/PlatformCodes.sol";
import "./libraries/ContractControllerErrorCodes.sol";

import "../WalletController/interfaces/IWalletControllerMarketManagement.sol";

import "../utils/Platform/Platform.sol";
import "../utils/interfaces/IUpgradableContract.sol";


contract ContractController is IContractControllerCodeManager, IUpgradableContract, IContractControllerRunLocal, ICCMarketDeployed, IContractControllerGetContractInfo {

    address ownerAddress;

    uint32 contractCodeVersion;

    mapping(uint8 => CodeStorage) contractCodes;

    mapping(uint8 => address[]) deployedContracts;
    mapping(address => uint8) knownContracts;
    // Contract is deployed as regular contract
    constructor(address ownerAddress_) public {
        tvm.accept();
        ownerAddress = ownerAddress_;
        contractCodeVersion = 0;
    }

    /*
        Data for upgrade from version 0 to version 1:
        data:
            bits:
                address ownerAddress
                uint32 codeVersion
            refs:
                1. mapping refs
                    refs:
                        1. mapping(uint8 => CodeStorage) contractCodes
                        2. mapping(uint8 => address[]) deployedContracts
                        3. mapping(address => uint8) knownContracts
     */
    // From version 0 to version 1
    function upgradeContractCode(TvmCell code, TvmCell updateParams, uint32 codeVersion_, uint8 contractType_) override external onlyOwner correctContractType(contractType_) newVersion(contractCodeVersion, codeVersion_) {
        tvm.accept();
        TvmBuilder dataBuilder;
        dataBuilder.store(ownerAddress);
        dataBuilder.store(codeVersion_);

        TvmBuilder mappingBuilder;
        TvmBuilder contractCodesStorage;
        TvmBuilder deployedContractsStorage;
        TvmBuilder knownContractsStorage;
        contractCodesStorage.store(contractCodes);
        deployedContractsStorage.store(deployedContracts);
        knownContractsStorage.store(knownContracts);

        mappingBuilder.store(contractCodesStorage.toCell());
        mappingBuilder.store(deployedContractsStorage.toCell());
        mappingBuilder.store(knownContractsStorage.toCell());

        dataBuilder.store(mappingBuilder);

        tvm.setcode(code);
        tvm.setCurrentCode(code);

        onCodeUpgrade(dataBuilder.toCell());
    }

    // From version 0 to version 1
    function onCodeUpgrade(TvmCell data) private {
        // some functions for upgrade
    }

    /*********************************************************************************************************/
    // Contract code managing functions
    /**
     * @param contractType Type of contract (check libraries/PlatfromCodes.sol)
     * @param code Contract code
     * @param codeVersion Version of contract code
     * @param deployCost Cost of deploying contract in nanotons
     */
    function addContractCode(uint8 contractType, TvmCell code, uint32 codeVersion, uint128 deployCost) override external onlyOwner contractTypeExists(contractType, false) {
        tvm.accept();
        contractCodes[contractType] = CodeStorage(code, codeVersion, deployCost);
    }

    /**
     * @param contractType Type of contract
     * @param code Updated contract code
     * @param codeVersion New code version
     */
    function updateContractCode(uint8 contractType, TvmCell code, uint32 codeVersion) override external onlyOwner contractTypeExists(contractType, true) {
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
    function setContractDeployCost(uint8 contractType, uint128 deployCost) override external onlyOwner contractTypeExists(contractType, true) {
        tvm.accept();
        contractCodes[contractType].deployCost = deployCost;
    }

    /**
     * @param contractType Type of contract
     * @param initialData InitialData for deployed smart contract
     * @param params Parameters for smart contract deployment
     */
    function createContract(uint8 contractType, TvmCell initialData, TvmCell params) override external responsible creator contractTypeExists(contractType, true) returns (address) {
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
        knownContracts[newContract] = contractType;
        deployedContracts[contractType].push(newContract);
        return { value: 0, bounce: false, flag: MsgFlag.REMAINING_GAS } newContract;
    }

    /**
     * @param contractType Type of contract
     * @param contractAddress Address of smart contract to update
     * @param updateParams Parameters required for update
     */
    function updateContract(uint8 contractType, address contractAddress, TvmCell updateParams) override external onlyOwner contractTypeExists(contractType, true) {
        tvm.accept();
        IUpgradableContract(contractAddress).upgradeContractCode{
            value: msg.value,
            bounce: true
        }(contractCodes[contractType].code, updateParams, contractCodes[contractType].codeVersion, contractType);
    }

    /**
     * @param contractType Type of contracts to update
     * @param updateParams Parameters passed to contracts during update
     */
    function updateContracts(uint8 contractType, TvmCell updateParams) override external onlyOwner contractTypeExists(contractType, true) {
        tvm.accept();
        TvmCell code = contractCodes[contractType].code;
        uint32 codeVersion = contractCodes[contractType].codeVersion;
        for (address contractAddress: deployedContracts[contractType]) {
            IUpgradableContract(contractAddress).upgradeContractCode(code, updateParams, codeVersion, contractType);
        }
    }

    /*********************************************************************************************************/
    // Special functions for market deployment
    // At least one Oracle and WalletController must be deployed before deploying markets
    /**
     * @param realTokenRoot Address of market's real token (ex. wTON)
     * @param virtualTokenRoot Address of market's virtual token (ex. vTON)
     */
    function marketDeployed(address realTokenRoot, address virtualTokenRoot) external override onlyKnownContract(PlatformCodes.MARKET) {
        tvm.accept();
        address market = msg.sender;

        for (address walletController: deployedContracts[PlatformCodes.WALLET_CONTROLLER]) {
            IWalletControllerMarketManagement(walletController).addMarket(market, realTokenRoot, virtualTokenRoot);
        }
    }
    
    /*********************************************************************************************************/
    // Getters, for local execution

    /**
     * @param contractType Type of contract
     */
    function getContractAddresses(uint8 contractType) external override responsible returns (address[]) {
        return { value: 0, bounce: false, flag: MsgFlag.REMAINING_GAS } deployedContracts[contractType];
    }

    /**
     * @param contractAddress Address of contract
     */
    function getContractType(address contractAddress) external override responsible returns (uint8) {
        return { value: 0, bounce: false, flag: MsgFlag.REMAINING_GAS } knownContracts[contractAddress];
    }

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
     * @param initialData Initial data used for contract
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
    modifier onlyOwner() {
        require(msg.sender == ownerAddress, ContractControllerErrorCodes.ERROR_MSG_SENDER_IS_NOT_ROOT);
        _;
    }

    /**
     * @param contractType Type of contract
     * @param exists Does contractType exist in contractCodes mapping
     */
    modifier contractTypeExists(uint8 contractType, bool exists) {
        require(contractCodes.exists(contractType) == exists, exists == true? ContractControllerErrorCodes.ERROR_CONTRACT_TYPE_DOES_NOT_EXIST : ContractControllerErrorCodes.ERROR_CONTRACT_TYPE_ALREADY_EXISTS);
        _;
    }
    
    /**
     * @param contractType Type of contract
     */
    modifier correctContractType(uint8 contractType) {
        require(contractType == PlatformCodes.CONTRACT_CONTROLLER, ContractControllerErrorCodes.ERROR_CONTRACT_TYPE_IS_INVALID);
        _;
    }

    /**
     * @notice Check if msg.sender is presented in mapping knownContracts
     * @param contractType Type of contract
     */
    modifier onlyKnownContract(uint8 contractType) {
        require(knownContracts[msg.sender] == contractType, ContractControllerErrorCodes.ERROR_MSG_SENDER_IS_NOT_KNOWN);
        _;
    }

    modifier creator() {
        require(msg.sender == ownerAddress || knownContracts[msg.sender] == PlatformCodes.USER_ACCOUNT_MANAGER, ContractControllerErrorCodes.ERROR_MSG_SENDER_IS_NOT_CREATOR);
        _;
    }

    modifier newVersion(uint32 oldCodeVersion, uint32 newCodeVersion) {
        require(oldCodeVersion < newCodeVersion, ContractControllerErrorCodes.ERROR_CODE_VERSION_IS_NOT_UPDATED);
        _;
    }

    /*********************************************************************************************************/
    /**
     * @param pubkey Owner pubkey
     * @param addr Owner address
     */
    function createInitialDataForOracle(uint256 pubkey, address addr) external override returns(TvmCell) {
        TvmBuilder initialData;
        initialData.store(pubkey, addr);
        return initialData.toCell();
    }

    function createInitialDataForUserAccountManager() external override returns(TvmCell) {
        TvmCell empty;
        return empty;
    }

    function createInitialDataForWalletController() external override returns(TvmCell) {
        TvmCell empty;
        return empty;
    }
}