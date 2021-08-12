const { abiContract } = require("@tonclient/core")
const Contract = require("locklift/locklift/contract")

/**
 * Encode message body
 * @param {Object} encodeMessageBodyParameters
 * @param {Contract} encodeMessageBodyParameters.contract 
 * @param {String} encodeMessageBodyParameters.functionName 
 * @param {JSON} encodeMessageBodyParameters.input 
 * @returns 
 */
async function encodeMessageBody({
    contract,
    functionName,
    input
}) {
    return await contract.locklift.ton.client.abi.encode_message_body({
        abi: abiContract(contract.abi),
        call_set: {
            function_name: functionName,
            input: input
        },
        is_internal: true,
        signer: signerNone()
    })
}

module.exports = {
    encodeMessageBody
}