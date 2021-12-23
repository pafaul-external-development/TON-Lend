const { convertCrystal } = require("locklift/locklift/utils");
const { loadEssentialContracts } = require("../../../utils/contracts");

async function main() {
    let contracts = await loadEssentialContracts({
        wallet: true,
        userAM: true
    });

    let payload = await contracts.userAccountManager.updateUserAccount({
        tonWallet: '0:7ad72c345cd1872806fbe7f16aca699e3f7a45bef316bbb65fdc0f279162b91e'// contracts.msigWallet.address
    });

    await contracts.msigWallet.transfer({
        destination: contracts.userAccountManager.address,
        value: convertCrystal(2, 'nano'),
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