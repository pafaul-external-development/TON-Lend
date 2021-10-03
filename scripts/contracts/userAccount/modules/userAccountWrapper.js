const { encodeMessageBody } = require('../../../utils/common');
const { ContractTemplate } = require('../../../utils/migration');

class UserAccount extends ContractTemplate {
    async getOwner() {
        return await this.call({
            method: 'getOwner',
            params: {},
            keyPair: this.keyPair
        });
    }

    async getKnownMarkets() {
        return await this.call({
            method: 'getKnownMarkets',
            params: {},
            keyPair: this.keyPair
        });
    }

    async getAllMarketsInfo() {
        return await this.call({
            method: 'getAllMarketsInfo',
            params: {},
            keyPair: this.keyPair
        });
    }

    /**
     * 
     * @param {Object} param0 
     * @param {Number} param0.marketId
     */
    async getMarketInfo({marketId}) {
        return await this.call({
            method: 'getMarketInfo',
            params: {
                marketId
            },
            keyPair: this.keyPair
        });
    }

    /**
     * 
     * @param {Object} param0 
     * @param {Number} param0.marketId
     * @param {Number} param0.loanId
     */
    async getLoanInfo({marketId, loanId}) {
        return await this.call({
            method: 'getLoanInfo',
            params: {
                marketId,
                loanId
            },
            keyPair: this.keyPair
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
            contract: this,
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
            contract: this,
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
            contract: this,
            functionName: 'withdrawExtraTons',
            input: {}
        });
    }
}

module.exports = {
    UserAccount
}