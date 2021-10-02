// @ts-check

const { abiContract, signerNone } = require("@tonclient/core")
const Contract = require("locklift/locklift/contract");
const { MarketsAggregator, toMarketsAggregator } = require("../../contracts/marketAggregator/modules/marketsAggregatorWrapper");
const { extendContractToOracle, Oracle } = require("../../contracts/oracle/modules/oracleWrapper");
const configuration = require("../../scripts.conf");
const { UserAccountManager, toUserAccountManager } = require("../../contracts/userAccount/modules/userAccountManagerWrapper");
const { UserAccount, toUserAccount } = require("../../contracts/userAccount/modules/userAccountWrapper");
const { MsigWallet, extendContractToWallet } = require("../../contracts/wallet/modules/walletWrapper");
const initializeLocklift = require("../initializeLocklift");
const { loadContractData } = require("../migration/_manageContractData");
const { Locklift } = require('locklift/locklift');
const { WalletController } = require("../../contracts/walletController/modules/walletControllerWrapper");
const { Module } = require("../../contracts/marketModules/modules/moduleWrapper");

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
 * @typedef {Object} Modules
 * @property {Module} supply
 * @property {Module} withdraw
 * @property {Module} borrow
 * @property {Module} repay
 */

/**
 * @typedef {Object} EssentialContracts
 * @property {Locklift} locklift
 * @property {MsigWallet} msigWallet
 * @property {MarketsAggregator} marketsAggregator
 * @property {Oracle} oracle
 * @property {UserAccountManager} userAccountManager
 * @property {UserAccount} userAccount
 * @property {WalletController} walletController
 * @property {Modules} modules
 */

/**
 * 
 * @param {Object} p
 * @param {Boolean} p.wallet
 * @param {Boolean} p.market
 * @param {Boolean} p.oracle
 * @param {Boolean} p.userAM
 * @param {Boolean} p.user
 * @param {Boolean} p.walletC
 * @param {Boolean} p.marketModules
 * @returns {Promise<EssentialContracts>}
 */
async function loadEssentialContracts({wallet = false, market = false, oracle = false, userAM = false, user = false, walletC = false, marketModules = false}) {
    let locklift = await initializeLocklift(configuration.pathToLockliftConfig, configuration.network);

    /**
     * @type {MsigWallet}
     */
    let msigWallet = undefined;
    if (wallet) {
        msigWallet = await loadContractData(locklift, 'MsigWallet');
        msigWallet = extendContractToWallet(msigWallet);
    }

    /**
     * @type {MarketsAggregator}
     */
    let marketsAggregator = undefined;
    if (market) {
        marketsAggregator = await loadContractData(locklift, 'MarketsAggregator');
        marketsAggregator = toMarketsAggregator(marketsAggregator);
    }

    /**
     * @type {Oracle}
     */
    let oracleContract = undefined;
    if (oracle) {
        oracleContract = await loadContractData(locklift, 'Oracle');
        oracleContract = extendContractToOracle(oracleContract);
    }

    /**
     * @type {UserAccountManager}
     */
    let userAccountManager = undefined;
    if (userAM) {
        userAccountManager = await loadContractData(locklift, 'UserAccountManager');
        userAccountManager = toUserAccountManager(userAccountManager);
    }

    /**
     * @type {UserAccount}
     */
    let userAccount = undefined;
    if (user) {
        userAccount = await loadContractData(locklift, 'UserAccount');
        userAccount = toUserAccount(userAccount);
    }

    /**
     * @type {WalletController}
     */
    let walletController = undefined;
    if (walletC) {
        let tmp = await loadContractData(locklift, 'WalletController');
        walletController = new WalletController(tmp);
    }

    /**
     * @type {Modules}
     */
    let modules = {};
    if (marketModules) {
        modules.supply = new Module(await loadContractData(locklift, 'SupplyModule'));
        modules.withdraw = new Module(await loadContractData(locklift, 'WithdrawModule'));
        modules.borrow = new Module(await loadContractData(locklift, 'BorrowModule'));
        modules.repay = new Module(await loadContractData(locklift, 'RepayModule'));
    }

    return {
        locklift,
        msigWallet,
        marketsAggregator,
        oracle: oracleContract,
        userAccountManager,
        userAccount,
        walletController,
        modules
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