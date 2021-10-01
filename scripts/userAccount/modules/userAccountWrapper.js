const Contract = require('locklift/locklift/contract');
const { encodeMessageBody } = require('../../utils/utils');

class UserAccount extends Contract {
    /**
     * 
     * @param {Object} param0 
     * @param {Number} param0._answer_id
     */
    async getOwner({_answer_id}) {}

    /**
     * 
     * @param {Object} param0 
     * @param {Number} param0._answer_id
     */
    async getKnownMarkets({_answer_id}) {}

    /**
     * 
     * @param {Object} param0 
     * @param {Number} param0._answer_id
     */
    async getAllMarketsInfo({_answer_id}) {}

    /**
     * 
     * @param {Object} param0 
     * @param {Number} param0._answer_id
     * @param {Number} param0.marketId
     */
    async getMarketInfo({_answer_id, marketId}) {}

    /**
     * 
     * @param {Object} param0 
     * @param {Number} param0._answer_id
     * @param {Number} param0.marketId
     * @param {Number} param0.loanId
     */
    async getLoanInfo({_answer_id, marketId, loanId}) {}

    /**
     * 
     * @param {Object} param0 
     * @param {Number} param0.marketId
     * @param {Number} param0.amountToBorrow
     * @param {String} param0.userTip3Wallet
     */
    async borrow({marketId, amountToBorrow, userTip3Wallet}) {}

    /**
     * 
     * @param {Object} param0 
     * @param {Number} param0.marketId
     */
    async enterMarket({marketId}) {}

    async withdrawExtraTons({}) {}
}

/**
 * 
 * @param {Contract} contract 
 * @returns {UserAccount}
 */
function toUserAccount(contract) {
    contract.getOwner = async function({_answer_id = 0}) {
        return await contract.call({
            method: 'getOwner',
            params: {
                _answer_id
            },
            keyPair: contract.keyPair
        });
    }

    contract.getKnownMarkets = async function({_answer_id = 0}) {
        return await contract.call({
            method: 'getKnownMarkets',
            params: {
                _answer_id
            },
            keyPair: contract.keyPair
        });
    }

    contract.getAllMarketsInfo = async function({_answer_id = 0}) {
        return await contract.call({
            method: 'getAllMarketsInfo',
            params: {
                _answer_id
            },
            keyPair: contract.keyPair
        });
    }

    contract.getMarketInfo = async function({_answer_id = 0, marketId}) {
        return await contract.call({
            method: 'getMarketInfo',
            params: {
                _answer_id,
                marketId
            },
            keyPair: contract.keyPair
        });
    }

    contract.getLoanInfo = async function({_answer_id = 0, marketId, loanId}) {
        return await contract.call({
            method: 'getLoanInfo',
            params: {
                _answer_id,
                marketId,
                loanId
            },
            keyPair: contract.keyPair
        });
    }

    contract.borrow = async function({marketId, amountToBorrow, userTip3Wallet}) {
        return await encodeMessageBody({
            contract,
            functionName: 'borrow',
            input: {
                marketId,
                amountToBorrow,
                userTip3Wallet
            }
        });
    }

    contract.enterMarket = async function({marketId}) {
        return await encodeMessageBody({
            contract,
            functionName: 'enterMarket',
            input: {
                marketId
            }
        });
    }

    contract.withdrawExtraTons = async function({}) {
        return await encodeMessageBody({
            contract,
            functionName: 'withdrawExtraTons',
            input: {}
        });
    }
    
    return contract;
}

return {
    UserAccount,
    toUserAccount
}