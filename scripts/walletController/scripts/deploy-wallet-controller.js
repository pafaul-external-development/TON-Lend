const deployContract = require("../../utils/deployContract");

async function main() {
    await deployContract({
        contractName: 'WalletController'
    })
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
        process.exit(1);
    }
)