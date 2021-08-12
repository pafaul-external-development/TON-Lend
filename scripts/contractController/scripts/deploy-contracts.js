/**
 * Deploy sequence (if ContractController is already deployed):
 * 1. TIP3Deployer
 * 2. Oracle
 * 3. WalletController
 * 4. UserAccountController
 * 5. Market
 */

const { ContractController, extendContractToContractController } = require("../modules/contractControllerWrapper");

const initializeLocklift = require("../../initializeLocklift");
const { loadContractData } = require("../../migration/manageContractData");

const configuration = require("../../scripts.conf");
const { contractInfo, operationsCost } = require("../modules/contractControllerConstants");
const { describeError } = require("../modules/errorDescription");
const { extendContractToWallet, MsigWallet } = require("../../wallet/modules/walletWrapper");
const { operationFlags } = require("../../utils/transferFlags");
const { describeTransaction } = require("../../utils/utils");
const Contract = require("locklift/locklift/contract");
const { abiContract } = require("@tonclient/core");

async function main() {
    let locklift = await initializeLocklift(configuration.pathToLockliftConfig, configuration.network);

    /**
     * @type {Contract}
     */
    let platform = await locklift.factory.getContract('Platform', configuration.buildDirectory);

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

    await locklift.giver.giver.run({
        method: 'sendGrams',
        params: {
            dest: msigWallet.address,
            amount: locklift.utils.convertCrystal(150, 'nano')
        },
        keyPair: msigWallet.keyPair
    });

    let tip3DeployerContract = await locklift.factory.getContract(contractInfo.TIP3_DEPLOYER.name, configuration.buildDirectory);
    try {
        let tip3DeployerInitialData = await contractController.createInitialDataForTIP3Deployer(msigWallet.address);
        let tip3DeployerParams = await contractController.createParamsForTIP3Deployer();
        let tip3DeployerCreatePayload = await contractController.createContract(
            contractInfo.TIP3_DEPLOYER.id,
            tip3DeployerInitialData,
            tip3DeployerParams
        );
        console.log(await msigWallet.transfer(
            contractController.address,
            locklift.utils.convertCrystal(operationsCost.uploadContractCode + contractInfo.TIP3_DEPLOYER.deployTonCost, 'nano'),
            operationFlags.FEE_FROM_CONTRACT_BALANCE,
            false,
            tip3DeployerCreatePayload
        ));
    } catch (err) {
        console.log(describeError(err));
    }

    let oracleContract = await locklift.factory.getContract(contractInfo.ORACLE.name, configuration.buildDirectory);
    oracleContract.setKeyPair(msigWallet.keyPair);
    try {
        let oracleInitialData = await contractController.createInitialDataForOracle(
            '0x' + oracleContract.keyPair.public,
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
            locklift.utils.convertCrystal(operationsCost.uploadContractCode + contractInfo.ORACLE.deployTonCost, 'nano'),
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
        let walletControllerCreatePayload = await contractController.createContract(
            contractInfo.WALLET_CONTROLLER.id,
            walletControllerInitialData,
            walletControllerParams
        );
        console.log(await msigWallet.transfer(
            contractController.address,
            locklift.utils.convertCrystal(operationsCost.uploadContractCode + contractInfo.WALLET_CONTROLLER.deployTonCost, 'nano'),
            operationFlags.FEE_FROM_CONTRACT_BALANCE,
            false,
            walletControllerCreatePayload
        ));
    } catch (err) {
        console.log(describeError(err));
    }

    let UserAccountManagerContract = await locklift.factory.getContract(contractInfo.USER_ACCOUNT_MANAGER.name, configuration.buildDirectory);
    try {
        let userAccountManagerInitialData = await contractController.createInitialDataForUserAccountManager();
        let userAccountManagerParams = await contractController.createParamsForUserAccountManager();
        let userAccountManagerCreatePayload = await contractController.createContract(
            contractInfo.USER_ACCOUNT_MANAGER.id,
            userAccountManagerInitialData,
            userAccountManagerParams
        );
        console.log(await msigWallet.transfer(
            contractController.address,
            locklift.utils.convertCrystal(operationsCost.uploadContractCode + contractInfo.USER_ACCOUNT_MANAGER.deployTonCost, 'nano'),
            operationFlags.FEE_FROM_CONTRACT_BALANCE,
            false,
            userAccountManagerCreatePayload
        ));
    } catch (err) {
        console.log(describeError(err));
    }

    try {
        let tip3DeployerAddress = (await contractController.getContractAddresses(contractInfo.TIP3_DEPLOYER.id))[0];
        const {
            result: [{
                boc
            }]
        } = await locklift.ton.client.net.query_collection({
            collection: 'accounts',
            filter: {
                id: {
                    eq: tip3DeployerAddress,
                }
            },
            result: 'boc'
        });

        console.log(await locklift.ton.client.abi.decode_account_data({
            abi: abiContract(platform.abi),
            data: boc
        }));

        console.log(tip3DeployerAddress);
        console.log(await contractController.getContractAddresses(contractInfo.ORACLE.id));
        console.log(await contractController.getContractAddresses(contractInfo.WALLET_CONTROLLER.id));
        console.log(await contractController.getContractAddresses(contractInfo.USER_ACCOUNT_MANAGER.id));
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