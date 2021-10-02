const initializeLocklift = require("../../initializeLocklift");
const { loadContractData } = require("../../migration/manageContractData");
const configuration = require("../../scripts.conf");
const { ContractController, extendContractToContractController } = require("../modules/contractControllerWrapper");

async function main() {
    let locklift = await initializeLocklift(configuration.pathToLockliftConfig, configuration.network);
    /**
     * @type {ContractController}
     */
    let contractController = await loadContractData(locklift, `./${configuration.network}_ContractController.json`);
    contractController = extendContractToContractController(contractController);
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
        process.exit(1);
    }
)