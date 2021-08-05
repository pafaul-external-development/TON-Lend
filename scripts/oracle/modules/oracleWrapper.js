const Contract = require("locklift/locklift/contract");

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
     * @param {String} market 
     * @param {String} costToUSD 
     * @returns {Promise<Object>}
     */
    async externalUpdatePrice(market, costToUSD) {};

    /**
     * 
     * @param {String} market 
     * @returns {Promise<Object>}
     */
    async internalUpdatePrice(market) {};

    /**
     * 
     * @param {String} market 
     * @param {String} payload 
     * @returns {Promise<Object>}
     */
    async getMarketPrice(market, payload) {};

    /**
     * 
     * @param {String} payload 
     * @returns {Promise<Object>}
     */
    async getAllMarketsPrices(payload) {};

    /**
     * 
     * @param {String} market 
     * @param {String} swapPairAddress 
     * @param {Boolean} isLeft 
     * @returns {Promise<Object>}
     */
    async addMarket(market, swapPairAddress, isLeft) {};

    /**
     * 
     * @param {String} market 
     * @returns {Promise<Object>}
     */
    async removeMarket(market) {};
}


/**
 * Add Oracle functionality to Contract instance
 * @param {Contract} contract 
 * @returns {Oracle}
 */
function extendContractToOracle(contract) {
    contract.getVersion = async function() {
        return await contract.call({
            method: 'getVersion',
            params: {},
            keyPair: contract.keyPair
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
        return await contract.run({
            method: 'changeOwnerAddress',
            params: {
                newOwnerAddress: newOwnerAddress
            },
            keyPair: contract.keyPair
        })
    }

    contract.changeOwnerPubkey = async function(newOwnerPubkey) {
        return await contract.run({
            method: 'changeOwnerPubkey',
            params: {
                newOwnerPubkey: newOwnerPubkey
            },
            keyPair: contract.keyPair
        })
    }

    contract.externalUpdatePrice = async function(market, costToUSD) {
        return await contract.run({
            method: 'externalUpdatePrice',
            params: {
                market: market,
                costToUSD: costToUSD
            },
            keyPair: contract.keyPair
        })
    }

    contract.internalUpdatePrice = async function(market) {
        return await contract.run({
            method: 'internalUpdatePrice',
            params: {
                market: market
            },
            keyPair: contract.keyPair
        })
    }

    contract.getMarketPrice = async function(market, payload) {
        return await contract.call({
            method: 'getMarketPrice',
            params: {
                market: market,
                payload: payload
            },
            keyPair: contract.keyPair
        })
    }

    contract.getAllMarketsPrices = async function(payload) {
        return await contract.call({
            method: 'getAllMarketsPrices',
            params: {
                payload: payload
            },
            keyPair: contract.keyPair
        })
    }

    contract.addMarket = async function(market, swapPairAddress, isLeft) {
        return await contract.run({
            method: 'addMarket',
            params: {
                market: market,
                swapPairAddress: swapPairAddress,
                isLeft: isLeft
            },
            keyPair: contract.keyPair
        })
    }

    contract.removeMarket = async function(market) {
        return await contract.run({
            method: 'removeMarket',
            params: {
                market: market
            },
            keyPair: contract.keyPair
        })
    }

    return contract;
}

module.exports = {
    Oracle,
    extendContractToOracle
};