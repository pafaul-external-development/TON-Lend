const { loadEssentialContracts, deployContract } = require("../../../utils/contracts");

async function main() {
    let contracts = await loadEssentialContracts({wallet: true});
    await deployContract({
        contractName: 'Oracle',
        constructorParams: {
            _owner: contracts.msigWallet.address,
            _ownerPubkey: '0x' + contracts.msigWallet.keyPair.public
        },
        initParams: {
            nonce: 0
        }
    });
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
        process.exit(1);
    }
)