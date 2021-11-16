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

    console.log(`Zero version code exists: ${pp(await contracts.userAccountManager.getUserAccountCode({version: 0}) != 'te6ccgEBAQEAAgAAAA==')}`);

    console.log(`Contract code version: ${await contracts.userAccountManager.contractCodeVersion()}`);

    console.log(`Contract codes available: ${pp(await contracts.userAccountManager.userAccountCodes())}`);
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
        process.exit(1);
    }
)