// @ts-check

const { abiContract, signerNone } = require("@tonclient/core")
const Contract = require("locklift/locklift/contract");
const { MarketsAggregator, toMarketsAggregator } = require("../marketAggregator/modules/marketsAggregatorWrapper");
const { extendContractToOracle, Oracle } = require("../oracle/modules/oracleWrapper");
const configuration = require("../scripts.conf");
const { UserAccountManager, toUserAccountManager } = require("../userAccount/modules/userAccountManagerWrapper");
const { UserAccount, toUserAccount } = require("../userAccount/modules/userAccountWrapper");
const { MsigWallet, extendContractToWallet } = require("../wallet/modules/walletWrapper");
const initializeLocklift = require("./initializeLocklift");
const { loadContractData } = require("./migration/manageContractData");
const { Locklift } = require('locklift/locklift');
const { WalletController } = require("../walletController/modules/walletControllerWrapper");

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
    return (await contract.locklift.ton.client.abi.encode_message_body({
        abi: abiContract(contract.abi),
        call_set: {
            function_name: functionName,
            input: input
        },
        is_internal: true,
        signer: signerNone()
    })).body;
}

function describeTransaction(tx) {
    let description = '';
    description += `Tx ${tx.compute.success == true ? 'success':'fail'}\n`;
    description += `Fees: ${tx.fees.total_account_fees}`;
    return description;
}

/**
 * @typedef {Object} EssentialContracts
 * @property {Locklift} locklift
 * @property {MsigWallet} msigWallet
 * @property {MarketsAggregator} marketsAggregator
 * @property {Oracle} oracle
 * @property {UserAccountManager} userAccountManager
 * @property {UserAccount} userAccount
 * @property {WalletController} walletController
 */

/**
 * 
 * @param {Object} p
 * @param {Boolean} p.wallet
 * @param {Boolean} p.markets
 * @param {Boolean} p.oracle
 * @param {Boolean} p.userAM
 * @param {Boolean} p.user
 * @param {Boolean} p.walletC
 * @returns {Promise<EssentialContracts>}
 */
async function loadEssentialContracts({wallet = false, markets = false, oracle = false, userAM = false, user = false, walletC = false}) {
    let locklift = await initializeLocklift(configuration.pathToLockliftConfig, configuration.network);

    /**
     * @type {MsigWallet}
     */
    let msigWallet = undefined;
    if (wallet) {
        msigWallet = await loadContractData(locklift, configuration, 'MsigWallet');
        msigWallet = extendContractToWallet(msigWallet);
    }

    /**
     * @type {MarketsAggregator}
     */
    let marketsAggregator = undefined;
    if (markets) {
        marketsAggregator = await loadContractData(locklift, configuration, 'MarketsAggregator');
        marketsAggregator = toMarketsAggregator(marketsAggregator);
    }

    /**
     * @type {Oracle}
     */
    let oracleContract = undefined;
    if (oracle) {
        oracleContract = await loadContractData(locklift, configuration, 'Oracle');
        oracleContract = extendContractToOracle(oracleContract);
    }

    /**
     * @type {UserAccountManager}
     */
    let userAccountManager = undefined;
    if (userAM) {
        userAccountManager = await loadContractData(locklift, configuration, 'UserAccountManager');
        userAccountManager = toUserAccountManager(userAccountManager);
    }

    /**
     * @type {UserAccount}
     */
    let userAccount = undefined;
    if (user) {
        userAccount = await loadContractData(locklift, configuration, 'UserAccount');
        userAccount = toUserAccount(userAccount);
    }

    /**
     * @type {WalletController}
     */
    let walletController = undefined;
    if (walletC) {
        let tmp = await loadContractData(locklift, configuration, 'WalletController');
        walletController = new WalletController(tmp);
    }

    return {
        locklift,
        msigWallet,
        marketsAggregator,
        oracle: oracleContract,
        userAccountManager,
        userAccount,
        walletController
    }
}

const stringToBytesArray = (dataString) => {
    return Buffer.from(dataString).toString('hex')
};

module.exports = {
    encodeMessageBody,
    describeTransaction,
    stringToBytesArray,
    loadEssentialContracts
}