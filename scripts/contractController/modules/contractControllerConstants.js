/**
 * @typedef ContractInfo
 * @type {Object}
 * 
 * @property {String} name
 * @property {Number} deployTonCost
 * @property {Number} codeVersion
 * @property {Number} id
 */

const contractInfo = {
    PLATFORM: {
        name: 'Platform',
        deployTonCost: 5,
        codeVersion: 0,
        id: 0
    },
    CONTRACT_CONTROLLER: {
        name: 'ContractController',
        deployTonCost: 5,
        codeVersion: 0,
        id: 1
    },
    WALLET_CONTROLLER: {
        name: 'WalletController',
        deployTonCost: 5,
        codeVersion: 0,
        id: 2
    },
    ORACLE: {
        name: 'Oracle',
        deployTonCost: 5,
        codeVersion: 0,
        id: 3
    },
    USER_ACCOUNT_MANAGER: {
        name: 'UserAccountManager',
        deployTonCost: 5,
        codeVersion: 0,
        id: 4
    },
    USER_ACCOUNT: {
        name: 'UserAccount',
        deployTonCost: 5,
        codeVersion: 0,
        id: 5
    },
    MARKET: {
        name: 'Market',
        deployTonCost: 5,
        codeVersion: 0,
        id: 6
    }
}

const operationsCost = {
    uploadContractCode: 0.5,
    deployContract: 0.6
}

module.exports = {
    contractInfo,
    operationsCost
}