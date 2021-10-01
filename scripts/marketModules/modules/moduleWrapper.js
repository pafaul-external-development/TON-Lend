const Contract = require('locklift/locklift/contract');
const { encodeMessageBody } = require('../../utils/utils');

class Module extends Contract {
    /**
     * 
     * @param {Object} param0 
     * @param {Number} param0._answer_id
     */
    async sendActionId({_answer_id}) {}

    /**
     * 
     * @param {Object} param0 
     * @param {String} param0._marketAddress
     */
    async setMarketAdress({_marketAddress}) {}

    /**
     * 
     * @param {Object} param0 
     * @param {String} param0._userAccountManager
     */
    async setUserAccountManager({_userAccountManager}) {}

    /**
     * 
     * @param {Object} param0 
     * @param {String} param0._answer_id
     */
    async getContractAddresses({_answer_id}) {}
}

/**
 * 
 * @param {Contract} contract 
 * @returns {Module}
 */
function toModule(contract) {
    contract.sendActionId = async function({_answer_id = 0}) {
        return await contract.call({
            method: 'sendActionId',
            params: {
                _answer_id
            },
            keyPair: contract.keyPair
        });
    }

    contract.setMarketAdress = async function({_marketAddress}) {
        return await encodeMessageBody({
            contract,
            functionName: 'setMarketAddress',
            input: {
                _marketAddress
            }
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

    contract.getContractAddresses = async function({_answer_id = 0}) {
        return await contract.call({
            method: 'getContractAddresses',
            params: {
                _answer_id
            },
            keyPair: contract.keyPair
        });
    }

    return contract;
}

module.exports = {
    Module,
    toModule
}