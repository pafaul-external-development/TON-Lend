const { loadEssentialContracts } = require("../../../utils/contracts");

async function main() {
    let contracts = await loadEssentialContracts({
        wallet: true,
        userAM: true
    });

    console.log(`Owner: ${await contracts.userAccountManager.owner()}`);
    
    console.log(`Market address: ${await contracts.userAccountManager.marketAddress()}`);

    console.log(`Modules: ${JSON.stringify(await contracts.userAccountManager.modules(), null, '\t')}`);

    console.log(`Existing modules: ${JSON.stringify(await contracts.userAccountManager.existingModules(), null, '\t')}`);
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
        process.exit(1);
    }
)