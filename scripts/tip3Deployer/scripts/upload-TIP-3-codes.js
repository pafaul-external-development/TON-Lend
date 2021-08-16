const configuration = require("../../scripts.conf");
const initializeLocklift = require("../../utils/initializeLocklift");
const { operationCosts } = require('../modules/tip3DeployerConstants');

const { loadContractData } = require("../../utils/migration/manageContractData");
const { TIP3Deployer, extendContractToTIP3Deployer } = require('../modules/tip3DeployerWrapper');
const { MsigWallet, extendContractToWallet } = require("../../wallet/modules/walletWrapper");
const { operationFlags } = require("../../utils/transferFlags");
const { stringToBytesArray } = require("../../utils/utils");

async function main() {
    let locklift = await initializeLocklift(configuration.pathToLockliftConfig, configuration.network);
    /**
     * @type {TIP3Deployer}
     */
    let tip3DeployerContract = await loadContractData(locklift, configuration, `${configuration.network}_TIP3DeployerContract.json`);
    tip3DeployerContract = extendContractToTIP3Deployer(tip3DeployerContract);

    /**
     * @type {MsigWallet}
     */
    let msigWallet = await loadContractData(locklift, configuration, `${configuration.network}_MsigWallet.json`);
    msigWallet = extendContractToWallet(msigWallet);

    let rootTIP3Contract = await locklift.factory.getContract('RootTokenContract', configuration.buildDirectory);
    let walletTIP3Contract = await locklift.factory.getContract('TONTokenWallet', configuration.buildDirectory);

    let setTIP3RootCodePayload = await tip3DeployerContract.setTIP3RootContractCode(rootTIP3Contract.code);
    let setTIP3WalletCodePayload = await tip3DeployerContract.setTIP3WalletContractCode(walletTIP3Contract.code);


    await msigWallet.transfer(
        tip3DeployerContract.address,
        locklift.utils.convertCrystal(operationCosts.codeUpload, 'nano'),
        operationFlags.FEE_FROM_CONTRACT_BALANCE,
        false,
        setTIP3RootCodePayload
    );

    await msigWallet.transfer(
        tip3DeployerContract.address,
        locklift.utils.convertCrystal(operationCosts.codeUpload, 'nano'),
        operationFlags.FEE_FROM_CONTRACT_BALANCE,
        false,
        setTIP3WalletCodePayload
    );

    let result = await tip3DeployerContract.getServiceInfo();

    console.log(`Root contract code is correct: ${result.rootCode == rootTIP3Contract.code}`);
    console.log(`Wallet contract code is correct: ${result.walletCode == walletTIP3Contract.code}`);
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
        process.exit(1);
    }
)