const { loadEssentialContracts } = require("../../../utils/common");
const deployContract = require("../../../utils/common/_deployContract");

async function main() {
    let contracts = await loadEssentialContracts({wallet: true});
    await deployContract({
        contractName: 'UserAccountManager',
        constructorParams: {
            _owner: contracts.msigWallet.address
        },
        initParams: {}
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