const deployContract = require("../../../utils/common/_deployContract");

async function main() {
    await deployContract({
        contractName: 'SupplyModule'
    });

    await deployContract({
        contractName: 'BorrowModule'
    });

    await deployContract({
        contractName: 'RepayModule'
    });

    await deployContract({
        contractName: 'WithdrawModule'
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