const { convertCrystal } = require("locklift/locklift/utils");
const { loadEssentialContracts } = require("../../../utils/contracts");
const { userMarketToEnter } = require("../modules/config");

async function main() {
    let contracts = await loadEssentialContracts({
        wallet: true,
        user: true
    });

    let payload = await contracts.userAccount.enterMarket({...userMarketToEnter});

    await contracts.msigWallet.transfer({
        destination: contracts.userAccount.address,
        value: convertCrystal(3, 'nano'),
        payload
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