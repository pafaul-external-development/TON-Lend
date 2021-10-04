const { pp } = require("../../../utils/common");
const { loadEssentialContracts } = require("../../../utils/contracts");

async function main() {
    let contracts = await loadEssentialContracts({
        wallet: true,
        userAM: true
    });

    console.log(`Owner: ${await contracts.userAccountManager.owner()}`);
    
    console.log(`Market address: ${await contracts.userAccountManager.marketAddress()}`);

    console.log(`Modules: ${pp(await contracts.userAccountManager.modules())}`);

    console.log(`Existing modules: ${pp(await contracts.userAccountManager.existingModules())}`);

    console.log(`Existing codes: ${pp(await contracts.userAccountManager.getUserAccountCode({version: 2}))}`);
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
        process.exit(1);
    }
)