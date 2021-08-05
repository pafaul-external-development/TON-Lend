const Contract = require("locklift/locklift/contract");

/**
 * @classdesc Intreface for ContractController contract. Use extendContractToContractController to gain real functionality
 * @class
 * @name ContractController
 * @augments Contract
 */
class ContractController extends Contract {
    /**
     * Add contract code to contract controller
     * @param {Number} contractType 
     * @param {String} code 
     * @param {Number} codeVersion 
     * @param {String} deployCost 
     */
    async addContractCode(contractType, code, codeVersion, deployCost) {}

    /**
     * Update existing contract code
     * @param {Number} contractType 
     * @param {String} code 
     * @param {Number} codeVersion 
     */
    async updateContractCode(contractType, code, codeVersion) {}

    /**
     * Set contract deployment cost
     * @param {Number} contractType 
     * @param {String} deployCost 
     */
    async setContractDeployCost(contractType, deployCost) {}

    /**
     * Create contract from existing code
     * @param {Number} contractType 
     * @param {String} initialData 
     * @param {String} params 
     */
    async createContract(contractType, initialData, params) {}

    /**
     * Update already deployed contract
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
        return await contract.run({
            method: 'addContractCode',
            params: {
                contractType: contractType,
                code: code,
                codeVersion: codeVersion,
                deployCost: deployCost
            },
            keyPair: contract.keyPair
        })
    };

    contract.updateContractCode = async function(contractType, code, codeVersion) {
        return await contract.run({
            method: 'updateContractCode',
            params: {
                contractType: contractType,
                code: code,
                codeVersion: codeVersion
            },
            keyPair: contract.keyPair
        })
    };

    contract.setContractDeployCost = async function(contractType, deployCost) {
        return await contract.run({
            method: 'setContractDeployCost',
            params: {
                contractType: contractType,
                deployCost: deployCost
            },
            keyPair: contract.keyPair
        })
    };

    contract.createContract = async function(contractType, initialData, params) {
        return await contract.run({
            method: 'createContract',
            params: {
                contractType: contractType,
                initialData: initialData,
                params: params
            },
            keyPair: contract.keyPair
        })
    };

    contract.updateContract = async function(contractType, contractAddress, updateParams) {
        return await contract.run({
            method: 'updateContract',
            params: {
                contractType: contractType,
                contractAddress: contractAddress,
                updateParams: updateParams
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

    return contract;
}

module.exports = {
    extendContractToContractController,
    ContractController
}