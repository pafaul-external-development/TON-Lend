const initializeLocklift = require("../../initializeLocklift");
const { loadContractData } = require("../../migration/manageContractData");
const configuration = require("../../scripts.conf");
const { contractInfo } = require("../modules/contractControllerConstants");
const { ContractController, extendContractToContractController } = require("../modules/contractControllerWrapper");

async function main() {
    let locklift = await initializeLocklift(configuration.pathToLockliftConfig, configuration.network);
    /**
     * @type {ContractController}
     */
    let contractController = await loadContractData(locklift, configuration, `./${configuration.network}_ContractController.json`);
    contractController = extendContractToContractController(contractController);

    let platformContract = await locklift.factory.getContract(contractInfo.PLATFORM.name, configuration.buildDirectory);
    let result = await contractController.getCodeStorage(contractInfo.PLATFORM.id);
    console.log(`Platform: ${result.code == platformContract.code}, codeVersion: ${result.codeVersion}`);

    result = await contractController.getCodeStorage(contractInfo.CONTRACT_CONTROLLER.id);
    console.log(`CC: ${result.code == contractController.code}, codeVersion: ${result.codeVersion}`);

    let tip3DeployerContract = await locklift.factory.getContract(contractInfo.TIP3_DEPLOYER.name, configuration.buildDirectory);
    result = await contractController.getCodeStorage(contractInfo.TIP3_DEPLOYER.id);
    console.log(`TIP-3-Deployer: ${result.code == tip3DeployerContract.code}, codeVersion: ${result.codeVersion}`);

    let walletContract = await locklift.factory.getContract(contractInfo.WALLET_CONTROLLER.name, configuration.buildDirectory);
    result = await contractController.getCodeStorage(contractInfo.WALLET_CONTROLLER.id);
    console.log(`WalletController: ${result.code == walletContract.code}, codeVersion: ${result.codeVersion}`);

    let oracleContract = await locklift.factory.getContract(contractInfo.ORACLE.name, configuration.buildDirectory);
    result = await contractController.getCodeStorage(contractInfo.ORACLE.id);
    console.log(`Oracle: ${result.code == oracleContract.code}, codeVersion: ${result.codeVersion}`);

    let userAccountManagerContract = await locklift.factory.getContract(contractInfo.USER_ACCOUNT_MANAGER.name, configuration.buildDirectory);
    result = await contractController.getCodeStorage(contractInfo.USER_ACCOUNT_MANAGER.id);
    console.log(`UAM: ${result.code == userAccountManagerContract.code}, codeVersion: ${result.codeVersion}`);

    let userAccountContract = await locklift.factory.getContract(contractInfo.USER_ACCOUNT.name, configuration.buildDirectory);
    result = await contractController.getCodeStorage(contractInfo.USER_ACCOUNT.id);
    console.log(`UA: ${result.code == userAccountContract.code}, codeVersion: ${result.codeVersion}`);

    let marketContract = await locklift.factory.getContract(contractInfo.MARKET.name, configuration.buildDirectory);
    result = await contractController.getCodeStorage(contractInfo.MARKET.id);
    console.log(`Market: ${result.code == marketContract.code}, codeVersion: ${result.codeVersion}`);
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
        process.exit(1);
    }
)