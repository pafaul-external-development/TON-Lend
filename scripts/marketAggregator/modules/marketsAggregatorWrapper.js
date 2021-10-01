const Contract = require('locklift/locklift/contract');
const { encodeMessageBody } = require('../../utils/utils');

/**
 * @typedef Fraction
 * @type {Object}
 * @property {Number} nom
 * @property {Number} denom
 */

class MarketsAggregator extends Contract {
    /**
     * 
     * @param {Object} param0 
     * @param {String} param0.code
     * @param {String} param0.updateParams
     * @param {Number} param0.codeVersion
     */
    async upgradeContractCode({code, updateParams, codeVersion}) {};

    /**
     * 
     * @param {Object} param0 
     * @param {Number} _answer_id
     */
    async getServiceContractAddresses({_answer_id}) {}

    /**
     * 
     * @param {Object} param0 
     * @param {Number} _answer_id
     */
    async getTokenPrices({_answer_id}) {}

    /**
     * 
     * @param {Object} param0 
     * @param {Number} param0._answer_id
     * @param {Number} param0.marketId
     */
    async getMarketInformation({_answer_id, marketId}) {}

    /**
     * 
     * @param {Object} param0 
     * @param {Number} param0._answer_id
     */
    async getAllMarkets({_answer_id}) {}

    async withdrawExtraTons({}) {}

    /**
     * 
     * @param {Object} param0 
     * @param {Number} param0._answer_id
     */
    async getAllModules({_answer_id}) {}

    /**
     * 
     * @param {Object} p
     * @param {Number} p.marketId
     * @param {String} p.realToken
     * @param {Number} p.initialBalance
     * @param {Fraction} p._reserveFactor
     * @param {Fraction} p._kink
     * @param {Fraction} p._collateral
     * @param {Fraction} p._baseRate
     * @param {Fraction} p._mul
     * @param {Fraction} p._jumpMul
     */
    async createNewMarket({
        marketId,
        realToken,
        initialBalance, 
        _reserveFactor,
        _kink,
        _collateral,
        _baseRate,
        _mul,
        _jumpMul
    }) {}

    /**
     * 
     * @param {Object} param0 
     * @param {Number} param0.operationId
     * @param {String} param0.module
     */
    async addModule({operationId, module}) {}

    /**
     * 
     * @param {Object} param0 
     * @param {String} param0.tokenRoot
     */
    async forceUpdatePrice({tokenRoot}) {}

    async forceUpdateAllPrices({}) {}

    /**
     * 
     * @param {Object} param0 
     * @param {String} param0._userAccountManager
     */
    async setUserAccountManager({_userAccountManager}) {}

    /**
     * 
     * @param {Object} param0 
     * @param {String} param0._tip3WalletController
     */
    async setTip3WalletController({_tip3WalletController}) {}

    /**
     * 
     * @param {Object} param0 
     * @param {String} param0._oracle
     */
    async setOracleAddress({_oracle}) {}

    /**
     * 
     * @param {Object} param0 
     * @param {String} param0.newOwner
     */
    async transferOwnership({newOwner}) {}
}

/**
 * 
 * @param {Contract} contract 
 * @returns {MarketsAggregator}
 */
function toMarketsAggregator(contract) {
    contract.upgradeContractCode = async function({code, updateParams, codeVersion}) {
        return await encodeMessageBody({
            contract,
            functionName: 'upgradeContractCode',
            input: {
                code,
                updateParams, 
                codeVersion
            }
        });
    }

    contract.getServiceContractAddresses = async function({_answer_id = 0}) {
        return await contract.call({
            method: 'getServiceContractAddresses',
            params: {
                _answer_id
            },
            keyPair: contract.keyPair
        });
    }

    contract.getTokenPrices = async function({_answer_id = 0}) {
        return await contract.call({
            method: 'getTokenPrices',
            params: {
                _answer_id
            },
            keyPair: contract.keyPair
        });
    }

    contract.getMarketInformation = async function({_answer_id = 0, marketId}) {
        return await contract.call({
            method: 'getMarketInformation',
            params: {
                _answer_id,
                marketId 
            },
            keyPair: contract.keyPair
        });
    }

    contract.getAllMarkets = async function({_answer_id = 0}) {
        return await contract.call({
            method: 'getAllMarkets',
            params: {
                _answer_id
            },
            keyPair: contract.keyPair
        });
    }

    contract.withdrawExtraTons = async function({}) {
        return await encodeMessageBody({
            contract,
            functionName: 'withdrawExtraTons',
            input: {}
        });
    }

    contract.createNewMarket = async function({
        marketId,
        realToken,
        initialBalance, 
        _reserveFactor,
        _kink,
        _collateral,
        _baseRate,
        _mul,
        _jumpMul
    }) {
        return await encodeMessageBody({
            contract,
            functionName: 'createNewMarket',
            input: {
                marketId,
                realToken,
                initialBalance,
                _reserveFactor,
                _kink,
                _collateral,
                _baseRate,
                _mul,
                _jumpMul
            }
        });
    }

    contract.addModule = async function({operationId, module}) {
        return await encodeMessageBody({
            contract,
            functionName: 'addModule',
            input: {
                operationId,
                module
            }
        });
    }

    contract.forceUpdatePrice = async function({tokenRoot}) {
        return await encodeMessageBody({
            contract,
            functionName: 'forceUpdatePrice',
            input: {
                tokenRoot
            }
        });
    }
    
    contract.forceUpdateAllPrices = async function({}) {
        return await encodeMessageBody({
            contract,
            functionName: 'forceUpdateAllPrices',
            input: {}
        });
    }

    contract.setUserAccountManager = async function({_userAccountManager}) {
        return await encodeMessageBody({
            contract, 
            functionName: 'setUserAccountManager',
            input: {
                _userAccountManager
            }
        });
    }

    contract.setTip3WalletController = async function({_tip3WalletController}) {
        return await encodeMessageBody({
            contract,
            functionName: 'setTip3WalletController',
            input: {
                _tip3WalletController
            }
        });
    }

    contract.setOracleAddress = async function({_oracle}) {
        return await encodeMessageBody({
            contract,
            functionName: 'setOracleAddress',
            input: {
                _oracle
            }
        });
    }

    contract.transferOwnership = async function({newOwner}) {
        return await encodeMessageBody({
            contract,
            functionName: 'transferOwnership',
            input: {
                newOwner
            }
        });
    }

    return contract;
}

module.exports = {
    MarketsAggregator,
    toMarketsAggregator
}