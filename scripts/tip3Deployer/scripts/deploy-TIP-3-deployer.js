const deployContract = require("../../utils/deployContract");

async function main() {
    await deployContract({
        contractName: 'TIP3Deployer',
        constructorParams: {},
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