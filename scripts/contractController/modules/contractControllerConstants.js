/**
 * @typedef ContractInfo
 * @type {Object}
 * 
 * @property {String} name
 * @property {Number} deployTonCost
 * @property {Number} id
 */

/**
 * @type {Record<String, ContractInfo>}
 * @property {ContractInfo} PLATFORM
 * @property {ContractInfo} CONTRACT_CONTROLLER
 * @property {ContractInfo} WALLET_CONTROLLER
 * @property {ContractInfo} ORACLE
 * @property {ContractInfo} USER_ACCOUNT_MANAGER
 * @property {ContractInfo} USER_ACCOUNT
 * @property {ContractInfo} MARKET
 */
const contractInfo = {
    PLATFORM: {
        name: 'Platform',
        deployTonCost: 5,
        id: 0
    },
    CONTRACT_CONTROLLER: {
        name: 'ContractController',
        deployTonCost: 5,
        id: 1
    },
    WALLET_CONTROLLER: {
        name: 'WalletController',
        deployTonCost: 5,
        id: 2
    },
    ORACLE: {
        name: 'Oracle',
        deployTonCost: 5,
        id: 3
    },
    USER_ACCOUNT_MANAGER: {
        name: 'UserAccountManager',
        deployTonCost: 5,
        id: 4
    },
    USER_ACCOUNT: {
        name: 'UserAccount',
        deployTonCost: 5,
        id: 5
    },
    MARKET: {
        name: 'Market',
        deployTonCost: 5,
        id: 6
    }
}

module.exports = {
    contractInfo
}