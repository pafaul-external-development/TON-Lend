const { expect, config } = require('chai');
const { Locklift } = require('locklift/locklift');
const Contract = require('locklift/locklift/contract');
const logger = require('mocha-logger');
const initializeLocklift = require('../../initializeLocklift');

const configuration = require('../../scripts.conf');

/**
 * @type { Locklift }
 */
let locklift = undefined;

/**
 * @type { Contract }
 */
let ContractController = undefined;

/**
 * @type { Contract }
 */
contractController = undefined;

let keyPair = undefined;

describe('Deploy contract contoller', async function() {
    it('Load locklift', async function() {
        locklift = await initializeLocklift(configuration.pathToLockliftConfig, configuration.network);
        logger.success('Locklift object loaded');
    });

    it('Load contract controller contract', async function() {
        ContractController = await locklift.factory.getContract('ContractController', configuration.buildDirectory);
        logger.success('Contract controller loaded');
    });

    it('Generate random key', async function() {
        [keyPair] = await locklift.keys.getKeyPairs();
    });

    it('Deploy contract controller', async function() {
        try {
            contractController = await locklift.giver.deployContract({
                contract: ContractController,
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
            logger.error(`Contract was not deployed`);
            console.log(err);
        }
    });

    it('Exit', async function() {
        process.exit(0);
    })
});