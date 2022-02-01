const { convertCrystal } = require("locklift/locklift/utils");
const { loadEssentialContracts } = require("../../../utils/contracts");
const { Module } = require("../modules/moduleWrapper");

async function main() {
    let contracts = await loadEssentialContracts({
        marketModules: true,
        wallet: true
    });

    /**
     * @type {Module}
     */
    let module = contracts.modules.withdraw;
    let payload = await module.ownerGeneralUnlock({
        _locked: false
    });

    await contracts.msigWallet.transfer({
        destination: module.address,
        value: convertCrystal(0.3, 'nano'),
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