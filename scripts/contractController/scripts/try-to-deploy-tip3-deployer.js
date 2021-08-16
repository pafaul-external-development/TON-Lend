const Contract = require("locklift/locklift/contract");
const initializeLocklift = require("../../initializeLocklift");
const { loadContractData } = require("../../utils/migration/manageContractData");
const configuration = require("../../scripts.conf");
const { contractInfo } = require("../modules/contractControllerConstants");
const { ContractController, extendContractToContractController } = require("../modules/contractControllerWrapper");

async function main() {
    let locklift = await initializeLocklift(configuration.pathToLockliftConfig, configuration.network);
    let msigWallet = await loadContractData(locklift, configuration, `${configuration.network}_MsigWallet.json`);
    let testContract = await locklift.factory.getContract('TestContract', configuration.buildDirectory);
    let platformContract = await locklift.factory.getContract('Platform', configuration.buildDirectory);

    /**
     * @type {ContractController}
     */
    let contractController = await loadContractData(locklift, configuration, `${configuration.network}_ContractController.json`);
    contractController = extendContractToContractController(contractController);
    let tip3DeployerInitialData = await contractController.createInitialDataForTIP3Deployer(msigWallet.address)

    await locklift.giver.deployContract({
        contract: platformContract,
        constructorParams: {
            contractCode: testContract.code,
            params: tip3DeployerInitialData
        },
        initParams: {
            root: contractController.address,
            platformType: contractInfo.TIP3_DEPLOYER.id,
            initialData: tip3DeployerInitialData,
            platformCode: platformContract.code
        },
        keyPair: msigWallet.keyPair
    });

    testContract.setAddress(platformContract.address);

    console.log(await testContract.call({
        method: 'iExist',
        params: {
            _answer_id: 0
        },
        keyPair: msigWallet.keyPair
    }));
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
        process.exit(1);
    }
)