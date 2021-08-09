const Contract = require("locklift/locklift/contract");
const { Locklift } = require("locklift/locklift");
const { abiContract, signerNone } = require("@tonclient/core");
const { encodeMessageBody } = require("../../utils/utils");

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

    return contract;
}

module.exports = {
    extendContractToContractController,
    ContractController
}