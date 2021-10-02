const { encodeMessageBody } = require('../../../utils/common');
const { ContractTemplate } = require('../../../utils/migration');

class Module extends ContractTemplate {

    async sendActionId() {
        return await this.call({
            method: 'sendActionId',
            params: {},
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

    async getContractAddresses() {
        return await this.call({
            method: 'getContractAddresses',
            params: {},
            keyPair: this.keyPair
        });
    }
}

module.exports = {
    Module
}