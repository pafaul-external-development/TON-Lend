const { pp } = require("../../../utils/common");
const { loadEssentialContracts } = require("../../../utils/contracts");

async function main() {
    let contracts = await loadEssentialContracts({
        user: true
    });

    console.log(`Owner: ${await contracts.userAccount.getOwner()}`);

    console.log(`Known markets: ${pp(await contracts.userAccount.getKnownMarkets())}`);

    console.log(`Market info: ${pp(await contracts.userAccount.getAllMarketsInfo())}`);
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
        process.exit(1);
    }
)