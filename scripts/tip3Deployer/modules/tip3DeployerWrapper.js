const Contract = require('locklift/locklift/contract');
const { encodeMessageBody } = require('../../utils/utils');

/**
 * @classdesc Interface for TIP3Deployer contract. Use extendContractToTIP3Deployer to gain real functionality
 * @class
 * @name TIP3Deployer
 * @augments Contract
 */
class TIP3Deployer extends Contract {
    /**
     * Deploy TIP-3 token
     * @param {Object} rootInfo 
     * @param {String} deployGrams 
     * @param {String} pubkeyToInsert 
     */
    async deployTIP3(rootInfo, deployGrams, pubkeyToInsert) {}

    /**
     * Get future address of TIP-3 token with given parameters
     * @param {Object} rootInfo 
     * @param {String} pubkeyToInsert 
     */
    async getFutureTIP3Address(rootInfo, pubkeyToInsert) {}

    /**
     * Set RootTokenContract code
     * @param {String} _rootContractCode 
     */
    async setTIP3RootContractCode(_rootContractCode) {}

    /**
     * Set TONTokenWallet code
     * @param {String} _walletContractCode 
     */
    async setTIP3WalletContractCode(_walletContractCode) {}

    /**
     * Fetch RootTokenContract and TONTokenWallet codes
     */
    async getServiceInfo() {}
}

/**
 * Extend Contract to TIP3Deployer
 * @param {Contract} contract 
 * @returns {TIP3Deployer}
 */
function extendContractToTIP3Deployer(contract) {
    contract.deployTIP3 = async function(rootInfo, deployGrams, pubkeyToInsert) {
        return await encodeMessageBody({
            contract: contract,
            functionName: 'deployTIP3',
            input: {
                _answer_id: 0,
                rootInfo: rootInfo,
                deployGrams: deployGrams,
                pubkeyToInsert: pubkeyToInsert
            }
        });
    };

    contract.getFutureTIP3Address = async function(rootInfo, pubkeyToInsert) {
        return await contract.call({
            method: 'getFutureTIP3Address',
            params: {
                rootInfo: rootInfo,
                pubkeyToInsert: pubkeyToInsert
            },
            keyPair: contract.keyPair
        });
    };

    contract.setTIP3RootContractCode = async function(_rootContractCode) {
        return await encodeMessageBody({
            contract: contract,
            functionName: 'setTIP3RootContractCode',
            input: {
                _rootContractCode: _rootContractCode
            }
        });
    };

    contract.setTIP3WalletContractCode = async function(_walletContractCode) {
        return await encodeMessageBody({
            contract: contract,
            functionName: 'setTIP3WalletContractCode',
            input: {
                _walletContractCode: _walletContractCode
            }
        });
    };

    contract.getServiceInfo = async function() {
        return await contract.call({
            method: 'getServiceInfo',
            params: {},
            keyPair: contract.keyPair
        });
    };

    return contract;
}

module.exports = {
    TIP3Deployer,
    extendContractToTIP3Deployer
}