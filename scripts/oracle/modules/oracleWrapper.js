const Contract = require("locklift/locklift/contract");
const { encodeMessageBody } = require("../../utils/utils");

/**
 * @classdesc Intreface for Giver contract. Use extendContractToGiver to gain real functionality
 * @class
 * @name Oracle
 * @augments Contract
 */
class Oracle extends Contract {
    /**
     * 
     * @returns {Promise<Object>}
     */
    async getVersion() {};

    /**
     * 
     * @returns {Promise<Object>}
     */
    async getDetails() {};

    /**
     * 
     * @param {String} newOwnerPubkey 
     * @returns {Promise<Object>}
     */
    async changeOwnerPubkey(newOwnerPubkey) {};

    /**
     * 
     * @param {String} newOwnerAddress 
     * @returns {Promise<Object>}
     */
    async changeOwnerAddress(newOwnerAddress) {};

    /**
     * 
     * @param {String} tokenRoot
     * @param {String} costToUSD 
     * @returns {Promise<Object>}
     */
    async externalUpdatePrice(tokenRoot, costToUSD) {};

    /**
     * 
     * @param {String} tokenRoot
     * @returns {Promise<Object>}
     */
    async internalUpdatePrice(tokenRoot) {};

    /**
     * 
     * @param {String} tokenRoot 
     * @param {String} payload 
     * @returns {Promise<Object>}
     */
    async getTokenPrice(tokenRoot, payload) {};

    /**
     * 
     * @param {String} payload 
     * @returns {Promise<Object>}
     */
    async getAllTokenPrices(payload) {};

    /**
     * 
     * @param {String} tokenRoot 
     * @param {String} swapPairAddress 
     * @param {Boolean} isLeft 
     * @returns {Promise<Object>}
     */
    async addToken(tokenRoot, swapPairAddress, isLeft) {};

    /**
     * 
     * @param {String} tokenRoot 
     * @returns {Promise<Object>}
     */
    async removeToken(tokenRoot) {};
}


/**
 * Add Oracle functionality to Contract instance
 * @param {Contract} contract 
 * @returns {Oracle}
 */
function extendContractToOracle(contract) {
    contract.getVersion = async function() {
        return await encodeMessageBody({
            contract: contract,
            functionName: 'getVersion',
            input: {}
        })
    }

    contract.getDetails = async function() {
        return await contract.call({
            method: 'getDetails',
            params: {},
            keyPair: contract.keyPair
        })
    }

    contract.changeOwnerAddress = async function(newOwnerAddress) {
        return await encodeMessageBody({
            contract: contract,
            functionName: 'changeOwnerAddress',
            input: {
                newOwnerAddress: newOwnerAddress
            }
        })
    }

    contract.changeOwnerPubkey = async function(newOwnerPubkey) {
        return await encodeMessageBody({
            contract: contract,
            functionName: 'changeOwnerPubkey',
            input: {
                newOwnerPubkey: newOwnerPubkey
            }
        })
    }

    contract.externalUpdatePrice = async function(tokenRoot, costToUSD) {
        return await encodeMessageBody({
            contract: contract,
            functionName: 'externalUpdatePrice',
            input: {
                tokenRoot: tokenRoot,
                costToUSD: costToUSD
            }
        })
    }

    contract.internalUpdatePrice = async function(tokenRoot) {
        return await encodeMessageBody({
            contract: contract,
            functionName: 'internalUpdatePrice',
            input: {
                tokenRoot: tokenRoot
            }
        })
    }

    contract.getTokenPrice = async function(tokenRoot, payload) {
        return await contract.call({
            method: 'getTokenPrice',
            params: {
                tokenRoot: tokenRoot,
                payload: payload
            },
            keyPair: contract.keyPair
        })
    }

    contract.getAllTokenPrices = async function(payload) {
        return await contract.call({
            method: 'getAllTokenPrices',
            params: {
                payload: payload
            },
            keyPair: contract.keyPair
        })
    }

    contract.addToken = async function(tokenRoot, swapPairAddress, isLeft) {
        return await encodeMessageBody({
            contract: contract,
            functionName: 'addToken',
            input: {
                tokenRoot: tokenRoot,
                swapPairAddress: swapPairAddress,
                isLeft: isLeft
            }
        })
    }

    contract.removeToken = async function(tokenRoot) {
        return await encodeMessageBody({
            contract: contract,
            functionName: 'removeToken',
            input: {
                tokenRoot: tokenRoot
            }
        })
    }

    return contract;
}

module.exports = {
    Oracle,
    extendContractToOracle
};