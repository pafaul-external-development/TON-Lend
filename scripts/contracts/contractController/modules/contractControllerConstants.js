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
    },
    TIP3_DEPLOYER: {
        name: 'TIP3Deployer',
        deployTonCost: 5,
        codeVersion: 0,
        id: 7
    }
}

const operationsCost = {
    uploadContractCode: 0.5,
    deployContract: 0.6
}

const testTokenRoot = '0:145cffcc0b44d428ec04fa5d6784714d8fd16b0e576761afca9ca4e536c3f747';

module.exports = {
    contractInfo,
    operationsCost,
    testTokenRoot
}