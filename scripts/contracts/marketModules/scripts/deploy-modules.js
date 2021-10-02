const { loadEssentialContracts } = require("../../../utils/common");
const deployContract = require("../../../utils/common/_deployContract");

async function main() {
    let contracts = await loadEssentialContracts({wallet: true});
    let modules = ['SupplyModule', 'BorrowModule', 'RepayModule', 'WithdrawModule'];
    let constructorParams = {
        _owner: contracts.msigWallet.address
    };
    for (let contractName of modules) {
        await deployContract({
            contractName,
            constructorParams
        });
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