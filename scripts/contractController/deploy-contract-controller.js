const { expect } = require('chai');
const { Locklift } = require('locklift/locklift');
const Contract = require('locklift/locklift/contract');
const logger = require('mocha-logger');

const configuration = require('../scripts.conf');

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
        locklift = await require('../initializeLocklift')('./scripts/l.conf.js', configuration.network);
        logger.success('Locklift object loaded');
    });

    it('Load contract controller contract', async function() {
        ContractController = await locklift.factory.getContract('ContractController', './build/');
        logger.success('Contract controller loaded');
    });

    it('Generate random key', async function() {
        keyPair = await locklift.keys.getKeyPairs();
    });

    it('Deploy contract controller', async function() {
        try {

            contractController = await locklift.giver.deployContract({
                contract: ContractController,
                initParams: {},
                constructorParams: {}
            })

            logger.success(`Contract controller deployed at ${contractController.address}`)
        } catch (err) {
            console.log(err);
        }
    });

    it('Exit', async function() {
        process.exit(0);
    })
});