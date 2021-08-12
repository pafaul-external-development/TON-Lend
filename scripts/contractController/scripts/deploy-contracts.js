/**
 * Deploy sequence (if ContractController is already deployed):
 * 1. TIP3Deployer
 * 2. Oracle
 * 3. UserAccountController
 * 4. Market
 */

const { ContractController, extendContractToContractController } = require("../modules/contractControllerWrapper");

const initializeLocklift = require("../../initializeLocklift");
const { loadContractData } = require("../../migration/manageContractData");

const configuration = require("../../scripts.conf");
const { contractInfo, operationsCost } = require("../modules/contractControllerConstants");
const { describeError } = require("../modules/errorDescription");
const { extendContractToWallet, MsigWallet } = require("../../wallet/modules/walletWrapper");
const { operationFlags } = require("../../utils/transferFlags");

async function main() {
    let locklift = await initializeLocklift(configuration.pathToLockliftConfig, configuration.network);
    /**
     * @type {ContractController}
     */
    let contractController = await loadContractData(locklift, configuration, `${configuration.network}_ContractController.json`);
    contractController = extendContractToContractController(contractController);

    /**
     * @type {MsigWallet}
     */
    let msigWallet = await loadContractData(locklift, configuration, `${configuration.network}_MsigWallet.json`);
    msigWallet = extendContractToWallet(msigWallet);

    let tip3DeployerContract = await locklift.factory.getContract(contractInfo.TIP3_DEPLOYER, configuration.buildDirectory);
    try {
        let tip3DeployerInitialData = await contractController.createInitialDataForTIP3Deployer
    }

    let oracleContract = await locklift.factory.getContract(contractInfo.ORACLE.name, configuration.buildDirectory);
    try {
        let oracleInitialData = await contractController.createInitialDataForOracle(
            oracleContract.keyPair.public,
            msigWallet.address
        );
        let oracleParams = await contractController.createParamsForOracle();
        let oracleCreatePayload = await contractController.createContract(
            contractInfo.ORACLE.id,
            oracleInitialData,
            oracleParams
        );
        console.log(await msigWallet.transfer(
            contractController.address,
            operationsCost.uploadContractCode,
            operationFlags.FEE_FROM_CONTRACT_BALANCE,
            false,
            oracleCreatePayload
        ));
    } catch (err) {
        console.log(describeError(err));
    }

    let walletControllerContract = await locklift.factory.getContract(contractInfo.WALLET_CONTROLLER.name, configuration.buildDirectory);
    try {
        let walletControllerInitialData = await contractController.createInitialDataForWalletController();
        let walletControllerParams = await contractController.createParamsForWalletController();
        let walletControllerCreatePayload = await contractController.addContractCode(
            contractInfo.WALLET_CONTROLLER.id,
            walletControllerInitialData,
            walletControllerParams
        );
        console.log(await msigWallet.transfer(
            contractController.address,
            operationsCost.uploadContractCode,
            operationFlags.FEE_FROM_CONTRACT_BALANCE,
            false,
            walletControllerCreatePayload
        ));
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