const { ContractTemplate } = require('../../../utils/migration');
const { encodeMessageBody } = require('../../utils/common/utils');

class Tip3Wallet extends ContractTemplate {
    async transfer({to, tokens, grams, send_gas_to, notify_receiver, payload}) {
        return await encodeMessageBody({
            contract: this,
            functionName: 'transfer',
            input: {
                to,
                tokens,
                grams,
                send_gas_to,
                notify_receiver,
                payload
            }
        });
    }
}

module.exports = {
    Tip3Wallet
}