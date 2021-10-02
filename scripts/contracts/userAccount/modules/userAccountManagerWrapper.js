const Contract = require('locklift/locklift/contract');
const { encodeMessageBody } = require('../../../utils/common');

class UserAccountManager extends Contract {
    /**
     * 
     * @param {Object} param0 
     * @param {String} param0.code
     * @param {String} param0.updateParams
     * @param {Number} param0.codeVersion
     */
    async upgradeContractCode({code, updateParams, codeVersion}) {
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

    /**
     * 
     * @param {Object} param0
     * @param {String} param0.tonWallet
     */
    async createUserAccount({tonWallet}) {
        return await encodeMessageBody({
            contract,
            functionName: 'createUserAccount',
            input: {
                _answer_id: 0,
                tonWallet
            }
        });
    }

    /**
     * 
     * @param {Object} param0 
     * @param {String} param0.tonWallet
     */
    async calculateUserAccoutAddress({tonWallet}) {
        return await this.call({
            method: 'calculateUserAccountAddress',
            params: {
                tonWallet
            },
            keyPair: this.keyPair
        });
    }

    /**
     * 
     * @param {Object} param0 
     * @param {String} param0._market
     */
    async setMarketAddress({_market}) {
        return await encodeMessageBody({
            contract,
            functionName: 'setMarketAddress',
            input: {
                _market
            }
        });
    }

    /**
     * 
     * @param {Object} param0 
     * @param {Number} param0.version
     * @param {String} param0.code
     */
    async uploadUserAccountCode({version, code}) {
        return await encodeMessageBody({
            contract,
            functionName: 'uploadUserAccountCode',
            input: {
                version,
                code
            }
        });
    }

    /**
     * 
     * @param {Object} param0 
     * @param {String} param0.tonWallet
     */
    async updateUserAccount({tonWallet}) {
        return await encodeMessageBody({
            contract,
            functionName: 'updateUserAccount',
            input: {
                tonWallet
            }
        });
    }

    /**
     * 
     * @param {Object} param0 
     * @param {Number} param0.version
     */
    async getUserAccountCode({version}) {
        return await this.call({
            method: 'getUserAccountCode',
            params: {
                version
            },
            keyPair: this.keyPair
        });
    }

    /**
     * 
     * @param {Object} param0 
     * @param {Number} param0.operationId
     * @param {String} param0.module
     */
    async addModule({operationId, module}) {
        return await encodeMessageBody({
            contract,
            functionName: 'addModule',
            input: {
                operationId,
                module
            }
        });
    }

    /**
     * 
     * @param {Object} param0 
     * @param {Number} param0.operationId
     */
    async removeModule({operationId}) {
        return await encodeMessageBody({
            contract,
            functionName: 'removeModule',
            input: {
                operationId
            }
        });
    }
}

module.exports = {
    UserAccountManager
}