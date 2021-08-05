const fs = require('fs');
const { Locklift } = require("locklift/locklift");
const Contract = require('locklift/locklift/contract');

const scriptConfiguration = require('../scripts.conf');

/**
 * @typedef ContractData
 * @type {Object}
 * @property {String} name
 * @property {String} address
 * @property {Object} keyPair
 * @property {String} network
 */

/**
 * Creates data required to use the contract later
 * @param {Contract} contract 
 * @param {Object} configuration
 * @returns {ContractData}
 */
function createContractData(contract, configuration) {
    /**
     * @type {ContractData}
     */
    let contractData = {};
    contractData.name = contract.name;
    contractData.address = contract.address;
    contractData.keyPair = contract.keyPair;
    contractData.network = configuration.network;
    return contractData;
}

/**
 * 
 * @param {Locklift} locklift 
 * @param {ContractData} contractData
 * @param {import('../scripts.conf').ScriptConfiguration} config
 */
async function loadContractFromData(locklift, contractData, config) {
    let contract = await locklift.factory.getContract(contractData.name, config.buildDirectory);
    if (contractData.network == config.network) {
        contract.address = contractData.address;
        contract.keyPair = contractData.keyPair;
    }

    return contract;
}


/**
 * 
 * @param {Contract} contract 
 * @param {String} filename
 */
function writeContractData(contract, filename) {
    fs.writeFileSync(filename, JSON.stringify(createContractData(contract, scriptConfiguration), null, '\t'));
}

/**
 * 
 * @param {Locklift} locklift 
 * @param {import('../scripts.conf').ScriptConfiguration} configuration 
 * @param {String} filename 
 * @returns 
 */
async function loadContractData(locklift, configuration, filename) {
    let data = JSON.parse(fs.readFileSync(filename));
    return loadContractFromData(locklift, configuration, data);
}

module.exports = {
    createContractData,
    loadContractFromData,
    writeContractData,
    loadContractData
}