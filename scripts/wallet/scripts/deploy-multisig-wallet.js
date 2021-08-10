const { Locklift } = require('locklift/locklift');
const Contract = require('locklift/locklift/contract');

const tryToExtractAddress = require('../../errorHandler/errorHandler');
const { writeContractData } = require('../../migration/manageContractData');

const initializeLocklift = require('../../initializeLocklift');
const configuration = require('../../scripts.conf');

async function main() {
    let locklift = initializeLocklift(configuration.pathToLockliftConfig, configuration.network);

    let walletContract = await locklift.factory.getContract('MultisigWallet', configuration.buildDirectory);

    let [keyPair] = await locklift.keys.getKeyPairs();
    walletContract.setKeyPair(keyPair);

    try {
        await locklift.giver.deployContract({
            contract: walletContract,
            constructorParams: {
                owners: [walletContract.keyPair.public],
                reqConfirms: 1
            },
            initParams: {},
            keyPair: walletContract.keyPair
        });

        if (walletContract.address) {
            console.log(`Multisig wallet deployed at address: ${walletContract.address}`);
        }
    } catch (err) {
        console.log(err);
        let address = tryToExtractAddress(err);
        if (address) {
            walletContract.setAddress(address);
            console.log(`Multisig wallet already deployed at address ${walletContract.address}`);
        }
    }

    if (walletContract.address) {
        await writeContractData(walletContract, 'MsigWallet.json');
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