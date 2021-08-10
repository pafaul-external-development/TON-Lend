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
    let contractController = await loadContractData(locklift, configuration, `./${configuration.network}_ContractController.json`);
    contractController = extendContractToContractController(contractController);

    /**
     * @type {MsigWallet}
     */
    let msigWallet = await loadContractData(locklift, configuration, `${configuration.network}_MsigWallet.json`);
    msigWallet = extendContractToWallet(msigWallet);

    let platformContract = await locklift.factory.getContract(contractInfo.PLATFORM.name, configuration.buildDirectory);
    try {
        let platformUploadPayload = await contractController.addContractCode(
            contractInfo.PLATFORM.id,
            platformContract.code,
            contractInfo.PLATFORM.codeVersion,
            locklift.utils.convertCrystal(contractInfo.PLATFORM.deployTonCost, 'nano')
        );
        console.log(await msigWallet.transfer(
            contractController.address,
            operationsCost.uploadContractCode,
            operationFlags.FEE_FROM_CONTRACT_BALANCE,
            false,
            platformUploadPayload
        ));
    } catch (err) {
        console.log(describeError(err));
    }

    try {
        let contractControllerUploadPayload = await contractController.addContractCode(
            contractInfo.CONTRACT_CONTROLLER.id,
            contractController.code,
            contractInfo.CONTRACT_CONTROLLER.codeVersion,
            locklift.utils.convertCrystal(contractInfo.CONTRACT_CONTROLLER.deployTonCost, 'nano')
        );
        console.log(await msigWallet.transfer(
            contractController.address,
            operationsCost.uploadContractCode,
            operationFlags.FEE_FROM_CONTRACT_BALANCE,
            false,
            contractControllerUploadPayload
        ));
    } catch (err) {
        console.log(describeError(err));
    }

    let oracleContract = await locklift.factory.getContract(contractInfo.ORACLE.name, configuration.buildDirectory);
    try {
        let oracleUpdloadPayload = await contractController.addContractCode(
            contractInfo.ORACLE.id,
            oracleContract.code,
            contractInfo.ORACLE.codeVersion,
            locklift.utils.convertCrystal(contractInfo.ORACLE.deployTonCost, 'nano')
        );
        console.log(await msigWallet.transfer(
            contractController.address,
            operationsCost.uploadContractCode,
            operationFlags.FEE_FROM_CONTRACT_BALANCE,
            false,
            oracleUpdloadPayload
        ));
    } catch (err) {
        console.log(describeError(err));
    }

    let walletContract = await locklift.factory.getContract(contractInfo.WALLET_CONTROLLER.name, configuration.buildDirectory);
    try {
        let walletControllerUploadPayload = await contractController.addContractCode(
            contractInfo.WALLET_CONTROLLER.id,
            walletContract.code,
            contractInfo.WALLET_CONTROLLER.codeVersion,
            locklift.utils.convertCrystal(contractInfo.WALLET_CONTROLLER.deployTonCost, 'nano')
        );
        console.log(await msigWallet.transfer(
            contractController.address,
            operationsCost.uploadContractCode,
            operationFlags.FEE_FROM_CONTRACT_BALANCE,
            false,
            walletControllerUploadPayload
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