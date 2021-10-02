const deployContract = require("../../../utils/common/_deployContract");

async function main() {
    await deployContract({
        contractName: 'UserAccountManager',
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