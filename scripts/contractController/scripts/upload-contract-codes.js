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
    let contractController = await loadContractData(locklift, configuration, './contractController.json');
    contractController = extendContractToContractController(contractController);

    let platformContract = await locklift.factory.getContract(contractInfo.PLATFORM.name, configuration.buildDirectory);
    console.log(await contractController.addContractCode(contractInfo.PLATFORM.id, platformContract.code, 0, locklift.utils.convertCrystal(contractInfo.PLATFORM.deployTonCost, 'nano')));
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
        process.exit(1);
    }
)