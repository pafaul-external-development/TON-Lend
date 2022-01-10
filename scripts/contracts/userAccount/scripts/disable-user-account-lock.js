const { convertCrystal } = require("locklift/locklift/utils");
const { loadEssentialContracts } = require("../../../utils/contracts");


async function main() {
    let contracts = await loadEssentialContracts({
        wallet: true,
        userAM: true
    });

    let payload = await contracts.userAccountManager.disableUserAccountLock({
        tonWallet: "0:d4668ff0e7151d274626bb3ac242ccc825212abeac86614f408ab30c8a90b032" // contracts.msigWallet.address
    });

    await contracts.msigWallet.transfer({
        destination: contracts.userAccountManager.address,
        value: convertCrystal(1, 'nano'),
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