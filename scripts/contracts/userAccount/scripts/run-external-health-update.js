const { convertCrystal } = require("locklift/locklift/utils");
const { loadEssentialContracts } = require("../../../utils/contracts");

async function main() {
    let contracts = await loadEssentialContracts({
        market: true,
        wallet: true,
        userAM: true
    });

    let externalUpdatePayload = await contracts.userAccountManager.requestUserAccountHealthCalculation({
        tonWallet: '0:7ad72c345cd1872806fbe7f16aca699e3f7a45bef316bbb65fdc0f279162b91e'
    })

    await contracts.msigWallet.transfer({
        destination: contracts.userAccountManager.address,
        value: convertCrystal(3, 'nano'),
        payload: externalUpdatePayload
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