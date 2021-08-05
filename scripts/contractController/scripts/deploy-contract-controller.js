const { expect, config } = require('chai');
const { Locklift } = require('locklift/locklift');
const Contract = require('locklift/locklift/contract');
const logger = require('mocha-logger');
const tryToExtractAddress = require('../../errorHandler/errorHandler');
const initializeLocklift = require('../../initializeLocklift');
const { writeContractData } = require('../../migration/manageContractData');

const configuration = require('../../scripts.conf');
const { extendContractTocontractController, ContractController } = require('../modules/contractControllerWrapper');

/**
 * @type { Locklift }
 */
let locklift = undefined;

/**
 * @type { ContractController }
 */
let contractController = undefined;

let keyPair = undefined;

describe('Deploy contract contoller', async function() {
    it('Load locklift', async function() {
        locklift = await initializeLocklift(configuration.pathToLockliftConfig, configuration.network);
        logger.success('Locklift object loaded');
    })

    it('Load contract controller contract', async function() {
        contractController = await locklift.factory.getContract('contractController', configuration.buildDirectory);
        logger.success('Contract controller loaded');
    })

    it('Generate random key', async function() {
        [keyPair] = await locklift.keys.getKeyPairs();
        contractController.setKeyPair(keyPair);
    })

    it('Deploy contract controller', async function() {
        try {
            await locklift.giver.deployContract({
                contract: contractController,
                initParams: {},
                constructorParams: {},
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
    })

    it('Convert contract to contract controller', async function() {
        contractController = extendContractTocontractController(contractController);
    })

    it('Try to save contract information', async function() {
        await writeContractData(contractController, 'contractController.json');
    })

    it('Exit', async function() {
        process.exit(0);
    })
})