const { ContractTemplate } = require('../../../utils/migration');
const { encodeMessageBody } = require('../../utils/common/utils');

class Module extends ContractTemplate {
    /**
     * 
     * @param {Object} param0 
     * @param {Number} param0._answer_id
     */
    async sendActionId({_answer_id}) {
        return await this.call({
            method: 'sendActionId',
            params: {
                _answer_id
            },
            keyPair: this.keyPair
        });
    }

    /**
     * 
     * @param {Object} param0 
     * @param {String} param0._marketAddress
     */
    async setMarketAdress({_marketAddress}) {
        return await encodeMessageBody({
            contract: this,
            functionName: 'setMarketAddress',
            input: {
                _marketAddress
            }
        });
    }

    /**
     * 
     * @param {Object} param0 
     * @param {String} param0._userAccountManager
     */
    async setUserAccountManager({_userAccountManager}) {
        return await encodeMessageBody({
            contract: this, 
            functionName: 'setUserAccountManager',
            input: {
                _userAccountManager
            }
        });
    }

    /**
     * 
     * @param {Object} param0 
     * @param {String} param0._answer_id
     */
    async getContractAddresses({_answer_id}) {
        return await this.call({
            method: 'getContractAddresses',
            params: {
                _answer_id
            },
            keyPair: this.keyPair
        });
    }
}

module.exports = {
    Module
}