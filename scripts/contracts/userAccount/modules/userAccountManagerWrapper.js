 const Contract = require('locklift/locklift/contract');
const { encodeMessageBody } = require('../../utils/utils');

class UserAccountManager extends Contract {
    /**
     * 
     * @param {Object} param0 
     * @param {String} param0.code
     * @param {String} param0.updateParams
     * @param {Number} param0.codeVersion
     */
    async upgradeContractCode({code, updateParams, codeVersion}) {}

    /**
     * 
     * @param {Object} param0 
     * @param {Number} param0._answer_id
     * @param {String} param0.tonWallet
     */
    async createUserAccount({_answer_id, tonWallet}) {}

    /**
     * 
     * @param {Object} param0 
     * @param {Number} param0._answer_id
     * @param {String} param0.tonWallet
     */
    async calculateUserAccoutAddress({_answer_id, tonWallet}) {}

    /**
     * 
     * @param {Object} param0 
     * @param {String} param0._market
     */
    async setMarketAddress({_market}) {}

    /**
     * 
     * @param {Object} param0 
     * @param {Number} param0.version
     * @param {String} param0.code
     */
    async uploadUserAccountCode({version, code}) {}

    /**
     * 
     * @param {Object} param0 
     * @param {String} param0.tonWallet
     */
    async updateUserAccount({tonWallet}) {}

    /**
     * 
     * @param {Object} param0 
     * @param {Number} param0._answer_id
     * @param {Number} param0.version
     */
    async getUserAccountCode({_answer_id, version}) {}

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
     * @param {Number} param0.operationId
     */
    async removeModule({operationId}) {}
}

/**
 * 
 * @param {Contract} contract 
 * @returns {UserAccountManager}
 */
function toUserAccountManager(contract) {
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

    contract.createUserAccount = async function({_answer_id = 0, tonWallet}) {
        return await encodeMessageBody({
            contract,
            functionName: 'createUserAccount',
            input: {
                _answer_id,
                tonWallet
            }
        });
    }

    contract.calculateUserAccoutAddress = async function({_answer_id = 0, tonWallet}) {
        return await contract.call({
            method: 'calculateUserAccountAddress',
            params: {
                _answer_id,
                tonWallet
            },
            keyPair: contract.keyPair
        });
    }

    contract.setMarketAddress = async function({_market}) {
        return await encodeMessageBody({
            contract,
            functionName: 'setMarketAddress',
            input: {
                _market
            }
        });
    }

    contract.uploadUserAccountCode = async function({version, code}) {
        return await encodeMessageBody({
            contract,
            functionName: 'uploadUserAccountCode',
            input: {
                version,
                code
            }
        });
    }

    contract.updateUserAccount = async function({tonWallet}) {
        return await encodeMessageBody({
            contract,
            functionName: 'updateUserAccount',
            input: {
                tonWallet
            }
        });
    }

    contract.getUserAccountCode = async function({_answer_id = 0, version}) {
        return await contract.call({
            method: 'getUserAccountCode',
            params: {
                _answer_id,
                version
            },
            keyPair: contract.keyPair
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

    contract.removeModule = async function({operationId}) {
        return await encodeMessageBody({
            contract,
            functionName: 'removeModule',
            input: {
                operationId
            }
        });
    }

    return contract;
}

module.exports = {
    UserAccountManager,
    toUserAccountManager
}