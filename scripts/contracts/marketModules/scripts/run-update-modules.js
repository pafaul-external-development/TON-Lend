const { convertCrystal } = require("locklift/locklift/utils");
const { loadEssentialContracts } = require("../../../utils/contracts");
const { Module } = require("../modules/moduleWrapper");

async function main() {
    let contracts = await loadEssentialContracts({
        marketModules: true,
        wallet: true
    });

    for (let moduleName in contracts.modules) {
        console.log(`Updating module: ${moduleName}`);
        let contractCodeVersion = 1;

        /**
         * @type {Module}
         */
        let module = contracts.modules[moduleName];
        let payload = await module.upgradeContractCode({
            code: module.code,
            updateParams: '',
            codeVersion: contractCodeVersion
        });

        await contracts.msigWallet.transfer({
            destination: module.address,
            value: convertCrystal(2, 'nano'),
            payload
        });
    }
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
        process.exit(1);
    }
)