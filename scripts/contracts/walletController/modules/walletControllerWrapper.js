const { encodeMessageBody } = require("../../../utils/common");
const { ContractTemplate } = require("../../../utils/migration/_contractTemplate");

class WalletController extends ContractTemplate {
    /**
     * 
     * @param {Object} param0 
     * @param {String} param0.code
     * @param {String} param0.updateParams
     * @param {Number} param0.codeVersion
     */
    async upgradeContractCode({code, updateParams, codeVersion}) {
        return await encodeMessageBody({
            contract: this,
            functionName: 'upgradeContractCode',
            input: {
                code,
                updateParams,
                codeVersion
            }
        });
    };

    /**
     * 
     * @param {Object} param0 
     * @param {String} param0._market
     */
    async setMarketAddress({_market}) {
        return await encodeMessageBody({
            contract: this,
            functionName: 'setMarketAddress',
            input: {
                _market
            }
        });
    }

    /**
     * 
     * @param {Object} param0 
     * @param {Number} param0.marketId
     * @param {String} param0.realTokenRoot
     * @param {String} param0.virtualTokenRoot
     */
    async addMarket({marketId, realTokenRoot, virtualTokenRoot}) {
        return await encodeMessageBody({
            contract: this,
            functionName: 'addMarket',
            input: {
                marketId,
                realTokenRoot,
                virtualTokenRoot
            }
        });
    }

    /**
     * 
     * @param {Object} param0 
     * @param {String} param0.marketId
     */
    async removeMarket({marketId}) {
        return await encodeMessageBody({
            contract: this,
            functionNamen: 'removeMarket',
            input: {
                marketId
            }
        })
    }

    async getRealTokenRoots() {
        return await this.call({
            method: 'getRealTokenRoots',
            params: {},
            keyPair: this.keyPair
        });
    }

    async getVirtualTokenRoots() {
        return await this.call({
            method: 'getVirtualTokenRoots',
            params: {},
            keyPair: this.keyPair
        });
    }

    async getWallets() {
        return await this.call({
            method: 'getWallets',
            params: {},
            keyPair: this.keyPair
        });
    }

    /**
     * 
     * @param {Object} param0
     * @param {Number} param0.marketId
     */
    async getMarketAddresses({marketId}) {
        return await this.call({
            method: 'getMarketAddresses',
            params: {
                marketId
            },
            keyPair: this.keyPair
        });
    }

    async getAllMarkets() {
        return await this.call({
            method: 'getAllMarkets',
            params: {},
            keyPair: this.keyPair
        });
    }

    /**
     * 
     * @param {Object} param0 
     * @param {String} param0.userVTokenWallet
     */
    async createSupplyPayload({userVTokenWallet}) {
        return await this.call({
            method: 'createSupplyPayload',
            params: {
                userVTokenWallet
            },
            keyPair: this.keyPair
        });
    }

    /**
     * 
     * @param {Object} param0 
     * @param {Number} param0.loanId
     */
    async createRepayPayload({loanId}) {
        return await this.call({
            method: 'createRepayPayload',
            params: {
                loanId
            },
            keyPair: this.keyPair
        });
    }

    /**
     * 
     * @param {Object} param0 
     * @param {String} param0.userTip3Wallet
     */
    async createWithdrawPayload({userTip3Wallet}) {
        return await this.call({
            method: 'createWithdrawPayload',
            params: {
                userTip3Wallet
            },
            keyPair: this.keyPair
        });
    }
}

module.exports = {
    WalletController
}