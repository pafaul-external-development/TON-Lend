const Contract = require('locklift/locklift/contract');

class UserAccountManager extends Contract {
    async upgradeContractCode({code, updateParams, codeVersion}) {}

    async createuserAccount({_answer_id, tonWallet}) {}

    async calculateUserAccoutAddress({_answer_id, tonWallet}) {}

    async setMarketAddress({_market}) {}

    async uploadUserAccountCode({version, code}) {}

    async updateUserAccount({tonWallet}) {}

    async getUserAccountCode({_answer_id, version}) {}

    async addModule({operationId, module}) {}

    async removeModule({operationId}) {}
}