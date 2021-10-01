const Contract = require('locklift/locklift/contract');
const { encodeMessageBody } = require('../../utils/utils');

class UserAccount extends Contract {
    async getOwner({_answer_id}) {}

    async borrow({marketId, amountToBorrow, userTip3Wallet}) {}

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
}

return {
    UserAccount,
    toUserAccount
}