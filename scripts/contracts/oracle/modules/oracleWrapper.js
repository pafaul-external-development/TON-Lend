const Contract = require("locklift/locklift/contract");
const { encodeMessageBody } = require("../../../utils/common");

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
    async getVersion() {
        return await encodeMessageBody({
            contract: contract,
            functionName: 'getVersion',
            input: {}
        })
    };

    /**
     * 
     * @returns {Promise<Object>}
     */
    async getDetails() {
        return await contract.call({
            method: 'getDetails',
            params: {},
            keyPair: contract.keyPair
        })
    };

    /**
     * @param {Object} p
     * @param {String} p.newOwnerPubkey 
     * @returns {Promise<Object>}
     */
    async changeOwnerPubkey({newOwnerPubkey}) {
        return await encodeMessageBody({
            contract: contract,
            functionName: 'changeOwnerPubkey',
            input: {
                newOwnerPubkey: newOwnerPubkey
            }
        })
    };

    /**
     * @param {Object} p
     * @param {String} p.newOwnerAddress 
     * @returns {Promise<Object>}
     */
    async changeOwnerAddress({newOwnerAddress}) {
        return await encodeMessageBody({
            contract: contract,
            functionName: 'changeOwnerAddress',
            input: {
                newOwnerAddress: newOwnerAddress
            }
        })
    };

    /**
     * @param {Object} p
     * @param {String} p.tokenRoot
     * @param {String} p.tokens
     * @param {String} p.usd 
     * @returns {Promise<Object>}
     */
    async externalUpdatePrice({tokenRoot, tokens, usd}) {
        return await encodeMessageBody({
            contract: contract,
            functionName: 'externalUpdatePrice',
            input: {
                tokenRoot: tokenRoot,
                tokens: tokens,
                usd: usd
            }
        })
    };

    /**
     * @param {Object} p 
     * @param {String} p.tokenRoot
     * @returns {Promise<Object>}
     */
    async internalUpdatePrice({tokenRoot}) {
        return await encodeMessageBody({
            contract: contract,
            functionName: 'internalUpdatePrice',
            input: {
                tokenRoot: tokenRoot
            }
        })
    };

    /**
     * @param {Object} p
     * @param {String} p.tokenRoot 
     * @param {String} p.payload 
     * @returns {Promise<Object>}
     */
    async getTokenPrice({tokenRoot, payload}) {
        return await contract.call({
            method: 'getTokenPrice',
            params: {
                tokenRoot: tokenRoot,
                payload: payload
            },
            keyPair: contract.keyPair
        })
    };

    /**
     * @param {Object} p
     * @param {String} p.payload 
     * @returns {Promise<Object>}
     */
    async getAllTokenPrices({payload}) {
        return await contract.call({
            method: 'getAllTokenPrices',
            params: {
                payload: payload
            },
            keyPair: contract.keyPair
        })
    };

    /**
     * @param {Object} p
     * @param {String} p.tokenRoot 
     * @param {String} p.swapPairAddress 
     * @param {Boolean} p.isLeft 
     * @returns {Promise<Object>}
     */
    async addToken({tokenRoot, swapPairAddress, isLeft}) {
        return await encodeMessageBody({
            contract: contract,
            functionName: 'addToken',
            input: {
                tokenRoot: tokenRoot,
                swapPairAddress: swapPairAddress,
                isLeft: isLeft
            }
        })
    };

    /**
     * @param {Object} p
     * @param {String} p.tokenRoot 
     * @returns {Promise<Object>}
     */
    async removeToken({tokenRoot}) {
        return await encodeMessageBody({
            contract: contract,
            functionName: 'removeToken',
            input: {
                tokenRoot: tokenRoot
            }
        })
    };
}

module.exports = {
    Oracle
};