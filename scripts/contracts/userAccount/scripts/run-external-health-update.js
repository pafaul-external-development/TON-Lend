const { convertCrystal } = require("locklift/locklift/utils");
const { loadEssentialContracts } = require("../../../utils/contracts");

async function main() {
    let contracts = await loadEssentialContracts({
        market: true,
        wallet: true,
        userAM: true
    });

    let externalUpdatePayload = await contracts.userAccountManager.requestUserAccountHealthCalculation({
        tonWallet: '0:d4668ff0e7151d274626bb3ac242ccc825212abeac86614f408ab30c8a90b032'
    })

    await contracts.msigWallet.transfer({
        destination: contracts.userAccountManager.address,
        value: convertCrystal(1, 'nano'),
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