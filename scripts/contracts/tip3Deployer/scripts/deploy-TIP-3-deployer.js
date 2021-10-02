const { deployContract } = require("../../utils/common");

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