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
     * @param {String} rootContractCode_ 
     */
    async setTIP3RootContractCode(rootContractCode_) {}

    /**
     * Set TONTokenWallet code
     * @param {String} walletContractCode_ 
     */
    async setTIP3WalletContractCode(walletContractCode_) {}

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

    contract.setTIP3RootContractCode = async function(rootContractCode_) {
        return await encodeMessageBody({
            contract: contract,
            functionName: 'setTIP3RootContractCode',
            input: {
                rootContractCode_: rootContractCode_
            }
        });
    };

    contract.setTIP3WalletContractCode = async function(walletContractCode_) {
        return await encodeMessageBody({
            contract: contract,
            functionName: 'setTIP3WalletContractCode',
            input: {
                walletContractCode_: walletContractCode_
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
}

module.exports = {
    TIP3Deployer,
    extendContractToTIP3Deployer
}