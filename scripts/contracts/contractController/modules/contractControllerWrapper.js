const Contract = require("locklift/locklift/contract");
const { Locklift } = require("locklift/locklift");
const { abiContract, signerNone } = require("@tonclient/core");
const { encodeMessageBody } = require("../../../utils/common");

/**
 * @classdesc Intreface for ContractController contract. Use extendContractToContractController to gain real functionality
 * @class
 * @name ContractController
 * @augments Contract
 */
class ContractController extends Contract {
    /**
     * Add contract code to contract controller (creates payload)
     * @param {Number} contractType 
     * @param {String} code 
     * @param {Number} codeVersion 
     * @param {String} deployCost 
     */
    async addContractCode(contractType, code, codeVersion, deployCost) {}

    /**
     * Update existing contract code (creates payload)
     * @param {Number} contractType 
     * @param {String} code 
     * @param {Number} codeVersion 
     */
    async updateContractCode(contractType, code, codeVersion) {}

    /**
     * Set contract deployment cost (creates payload)
     * @param {Number} contractType 
     * @param {String} deployCost 
     */
    async setContractDeployCost(contractType, deployCost) {}

    /**
     * Create contract from existing code (creates payload)
     * @param {Number} contractType 
     * @param {String} initialData 
     * @param {String} params 
     */
    async createContract(contractType, initialData, params) {}

    /**
     * Update already deployed contract (creates payload)
     * @param {Number} contractType 
     * @param {String} contractAddress 
     * @param {String} updateParams 
     */
    async updateContract(contractType, contractAddress, updateParams) {}

    /**
     * Get contract addresses of deployed contracts of contractType
     * @param {Number} contractType 
     */
    async getContractAddresses(contractType) {}

    /**
     * Get type of deployed contract
     * @param {String} contractAddress 
     */
    async getContractType(contractAddress) {}

    /**
     * Get code version
     * @param {Number} contractType 
     */
    async getCodeVersion(contractType) {}

    /**
     * Get code storage -> code, codeVersion, deployCost
     * @param {Number} contractType 
     */
    async getCodeStorage(contractType) {}

    /**
     * Calculate future address from initial data
     * @param {Number} contractType 
     * @param {String} initialData 
     */
    async calculateFutureAddress(contractType, initialData) {}

    /**
     * Create TvmCell with intialParameters for market contract
     * @param {String} tokenRoot 
     * @param {String} tip3Deployer 
     * @param {String} walletController 
     * @param {String} oracle 
     */
    async createInitialDataForMarket(tokenRoot, tip3Deployer, walletController, oracle) {}

    /**
     * Create TvmCell with params for market contract
     */
    async createParamsForMarket() {}

    /**
     * Create initial data for oracle smart contract
     * @param {String} pubkey 
     * @param {String} addr 
     */
    async createInitialDataForOracle(pubkey, addr) {}

    /**
     * Create TvmCell with params for oracle contract
     */
    async createParamsForOracle() {}

    /**
     * Create TvmCell with initialData for TIP3Deployer contract
     * @param {String} _ownerAddress 
     */
    async createInitialDataForTIP3Deployer(_ownerAddress) {}

    /**
     * Create TvmCell with params for TIP3Deployer contract
     */
    async createParamsForTIP3Deployer() {}

    /**
     * Create TvmCell with initialData for UserAccount contract
     * @param {String} msigOwner 
     */
    async createInitialDataForUserAccount(msigOwner) {}

    /**
     * Create TvmCell with params for UserAccount contract
     */
    async createParamsForUserAccount() {}

    /**
     * Create initial data for user account manager
     */
    async createInitialDataForUserAccountManager() {}

    /**
     * Create TvmCell with params for UserAccountManager contract
     */
    async createParamsForUserAccountManager() {}

    /**
     * Create initial data for wallet controller
     */
    async createInitialDataForWalletController() {}

    /**
     * Create TvmCell with params for WalletController contract
     */
    async createParamsForWalletController() {}
}


/**
 * 
 * @param {Contract} contract 
 * @returns {ContractController}
 */
function extendContractToContractController(contract) {
    contract.addContractCode = async function(contractType, code, codeVersion, deployCost) {
        return await encodeMessageBody({
            contract: contract,
            functionName: 'addContractCode',
            input: {
                contractType: contractType,
                code: code,
                codeVersion: codeVersion,
                deployCost: deployCost
            }
        })
    };

    contract.updateContractCode = async function(contractType, code, codeVersion) {
        return await encodeMessageBody({
            contract: contract,
            functionName: 'updateContractCode',
            input: {
                contractType: contractType,
                code: code,
                codeVersion: codeVersion
            },
        })
    };

    contract.setContractDeployCost = async function(contractType, deployCost) {
        return await encodeMessageBody({
            contract: contract,
            functionName: 'setContractDeployCost',
            input: {
                contractType: contractType,
                deployCost: deployCost
            }
        })
    };

    contract.createContract = async function(contractType, initialData, params) {
        return await encodeMessageBody({
            contract: contract,
            functionName: 'createContract',
            input: {
                contractType: contractType,
                initialData: initialData,
                params: params,
                _answer_id: 0
            },
        })
    };

    contract.updateContract = async function(contractType, contractAddress, updateParams) {
        return await encodeMessageBody({
            contract: contract,
            functionName: 'updateContract',
            input: {
                contractType: contractType,
                contractAddress: contractAddress,
                updateParams: updateParams
            }
        })
    };

    contract.getContractAddresses = async function(contractType) {
        return await contract.call({
            method: 'getContractAddresses',
            params: {
                contractType: contractType
            },
            keyPair: contract.keyPair
        })
    };

    contract.getContractType = async function(contractAddress) {
        return await contract.call({
            method: 'getContractType',
            params: {
                contractAddress: contractAddress
            },
            keyPair: contract.keyPair
        })
    };

    contract.getCodeVersion = async function(contractType) {
        return await contract.call({
            method: 'getCodeVersion',
            params: {
                contractType: contractType
            },
            keyPair: contract.keyPair
        })
    };

    contract.getCodeStorage = async function(contractType) {
        return await contract.call({
            method: 'getCodeStorage',
            params: {
                contractType: contractType
            },
            keyPair: contract.keyPair
        })
    };

    contract.calculateFutureAddress = async function(contractType, initialData) {
        return await contract.call({
            method: 'calculateFutureAddress',
            params: {
                contractType: contractType,
                initialData: initialData
            },
            keyPair: contract.keyPair
        })
    };

    contract.createInitialDataForMarket = async function(tokenRoot, tip3Deployer, walletController, oracle) {
        return await contract.call({
            method: 'createInitialDataForMarket',
            params: {
                tokenRoot: tokenRoot,
                tip3Deployer: tip3Deployer,
                walletController: walletController,
                oracle: oracle
            },
            keyPair: contract.keyPair
        });
    }

    contract.createParamsForMarket = async function() {
        return await contract.call({
            method: 'createParamsForMarket',
            params: {},
            keyPair: contract.keyPair
        });
    }

    contract.createInitialDataForOracle = async function(pubkey, addr) {
        return await contract.call({
            method: 'createInitialDataForOracle',
            params: {
                pubkey: pubkey,
                addr: addr
            },
            keyPair: contract.keyPair
        });
    }

    contract.createParamsForOracle = async function() {
        return await contract.call({
            method: 'createParamsForOracle',
            params: {},
            keyPair: contract.keyPair
        });
    }

    contract.createInitialDataForTIP3Deployer = async function(_ownerAddress) {
        return await contract.call({
            method: 'createInitialDataForTIP3Deployer',
            params: {
                _ownerAddress: _ownerAddress
            },
            keyPair: contract.keyPair
        });
    }

    contract.createParamsForTIP3Deployer = async function() {
        return await contract.call({
            method: 'createParamsForTIP3Deployer',
            params: {},
            keyPair: contract.keyPair
        });
    }

    contract.createInitialDataForUserAccount = async function(msigOwner) {
        return await contract.call({
            method: 'createInitialDataForUserAccount',
            params: {
                msigOwner: msigOwner
            },
            keyPair: contract.keyPair
        });
    }

    contract.createParamsForUserAccount = async function() {
        return await contract.call({
            method: 'createParamsForUserAccount',
            params: {},
            keyPair: contract.keyPair
        });
    }
    contract.createInitialDataForUserAccountManager = async function() {
        return await contract.call({
            method: 'createInitialDataForUserAccountManager',
            params: {},
            keyPair: contract.keyPair
        });
    }

    contract.createParamsForUserAccountManager = async function() {
        return await contract.call({
            method: 'createParamsForUserAccountManager',
            params: {},
            keyPair: contract.keyPair
        });
    }

    contract.createInitialDataForWalletController = async function() {
        return await contract.call({
            method: 'createInitialDataForWalletController',
            params: {},
            keyPair: contract.keyPair
        });
    }

    contract.createParamsForWalletController = async function() {
        return await contract.call({
            method: 'createParamsForWalletController',
            params: {},
            keyPair: contract.keyPair
        });
    }

    return contract;
}

module.exports = {
    extendContractToContractController,
    ContractController
}