const { encodeMessageBody } = require('../../../utils/common');
const { ContractTemplate } = require('../../../utils/migration');

class UserAccount extends ContractTemplate {
    async getOwner() {
        return await contract.call({
            method: 'getOwner',
            params: {
                _answer_id
            },
            keyPair: contract.keyPair
        });
    }

    async getKnownMarkets() {
        return await contract.call({
            method: 'getKnownMarkets',
            params: {
                _answer_id
            },
            keyPair: contract.keyPair
        });
    }

    async getAllMarketsInfo() {
        return await contract.call({
            method: 'getAllMarketsInfo',
            params: {
                _answer_id
            },
            keyPair: contract.keyPair
        });
    }

    /**
     * 
     * @param {Object} param0 
     * @param {Number} param0.marketId
     */
    async getMarketInfo({marketId}) {
        return await contract.call({
            method: 'getMarketInfo',
            params: {
                _answer_id,
                marketId
            },
            keyPair: contract.keyPair
        });
    }

    /**
     * 
     * @param {Object} param0 
     * @param {Number} param0.marketId
     * @param {Number} param0.loanId
     */
    async getLoanInfo({marketId, loanId}) {
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

    /**
     * 
     * @param {Object} param0 
     * @param {Number} param0.marketId
     * @param {Number} param0.amountToBorrow
     * @param {String} param0.userTip3Wallet
     */
    async borrow({marketId, amountToBorrow, userTip3Wallet}) {
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

    /**
     * 
     * @param {Object} param0 
     * @param {Number} param0.marketId
     */
    async enterMarket({marketId}) {
        return await encodeMessageBody({
            contract,
            functionName: 'enterMarket',
            input: {
                marketId
            }
        });
    }

    /**
     * 
     * @param {Object} param0 
     * @returns 
     */
    async withdrawExtraTons() {
        return await encodeMessageBody({
            contract,
            functionName: 'withdrawExtraTons',
            input: {}
        });
    }
}

module.exports = {
    UserAccount
}