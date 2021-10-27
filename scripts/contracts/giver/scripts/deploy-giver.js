const initializeLocklift = require("../../initializeLocklift");
const { writeContractData } = require("../../migration/manageContractData");

const configuration = require('../../../scripts.conf');
const extendContractToGiver = require("../modules/GiverWrapper");

async function main() {
    let locklift = initializeLocklift(configuration.pathToLockliftConfig, configuration.network);
    let [keyPair] = await locklift.keys.getKeyPairs();
    let giver = await locklift.factory.getContract('Giver', configuration.buildDirectory);
    giver = await locklift.giver.deployContract({
        contract: giver,
        initParams: {},
        constructorParams: {},
        keyPair
    });

    writeContractData(giver, 'giverData.js');

    let giverContract = extendContractToGiver(giver);
}

main().then(
    () => process.exit(0)
).catch((err) => {
    console.log(err);
    process.exit(1);
})