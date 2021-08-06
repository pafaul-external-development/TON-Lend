const { ContractController, extendContractToContractController } = require("../modules/contractControllerWrapper");

const initializeLocklift = require("../../initializeLocklift");
const { loadContractData } = require("../../migration/manageContractData");

const configuration = require("../../scripts.conf");
const { contractInfo } = require("../modules/contractControllerConstants");
const { describeError } = require("../modules/errorDescription");

async function main() {
    let locklift = await initializeLocklift(configuration.pathToLockliftConfig, configuration.network);
    /**
     * @type {ContractController}
     */
    let contractController = await loadContractData(locklift, configuration, './contractController.json');
    contractController = extendContractToContractController(contractController);

    let platformContract = await locklift.factory.getContract(contractInfo.PLATFORM.name, configuration.buildDirectory);
    try {
        console.log(await contractController.addContractCode(contractInfo.PLATFORM.id, platformContract.code, 0, locklift.utils.convertCrystal(contractInfo.PLATFORM.deployTonCost, 'nano')));
    } catch (err) {
        console.log(describeError(err));
    }

    let oracleContract = await locklift.factory.getContract(contractInfo.ORACLE.name, configuration.buildDirectory);
    try {
        console.log(await contractController.addContractCode(contractInfo.ORACLE.id, oracleContract.code, 0, locklift.utils.convertCrystal(contractInfo.ORACLE.deployTonCost, 'nano')));
    } catch (err) {
        console.log(describeError(err));
    }

    let walletContract = await locklift.factory.getContract(contractInfo.WALLET_CONTROLLER.name, configuration.buildDirectory);
    try {
        console.log(await contractController.addContractCode(contractInfo.WALLET_CONTROLLER.id, walletContract.code, 0, locklift.utils.convertCrystal(contractInfo.WALLET_CONTROLLER.deployTonCost, 'nano')));
    } catch (err) {
        console.log(describeError(err));
    }
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
        process.exit(1);
    }
)