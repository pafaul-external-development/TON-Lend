const { expect } = require('chai');
const { Locklift } = require('locklift/locklift');
const Contract = require('locklift/locklift/contract');
const logger = require('mocha-logger');
const tryToExtractAddress = require('../../errorHandler/errorHandler');
const initializeLocklift = require('../../initializeLocklift');
const { writeContractData, loadContractData } = require('../../migration/manageContractData');

const configuration = require('../../scripts.conf');
const { extendContractToContractController, ContractController } = require('../modules/contractControllerWrapper');

let keyPair = undefined;

async function main() {
    let locklift = await initializeLocklift(configuration.pathToLockliftConfig, configuration.network);
    logger.success('Locklift object loaded');

    let contractController = await locklift.factory.getContract('contractController', configuration.buildDirectory);
    logger.success('Contract controller loaded');

    let [keyPair] = await locklift.keys.getKeyPairs();
    contractController.setKeyPair(keyPair);

    let msigWallet = await loadContractData(locklift, configuration, `${configuration.network}_MsigWallet.json`);

    try {
        await locklift.giver.deployContract({
            contract: contractController,
            initParams: {},
            constructorParams: {
                ownerAddress_: msigWallet.address
            },
            keyPair
        })

        if (contractController.address) {
            logger.success(`Contract controller deployed at ${contractController.address}`);
        } else {
            logger.error(`Contract was not deployed`);
        }
    } catch (err) {
        let contractAddress = tryToExtractAddress(err);
        if (contractAddress) {
            logger.success(`Contract controller deployed at ${contractAddress}`);
            contractController.setAddress(contractAddress)
        }
    }

    if (contractController.address) {
        await writeContractData(contractController, `ContractController.json`);
    }

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