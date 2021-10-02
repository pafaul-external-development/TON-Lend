const { loadEssentialContracts } = require("../../../utils/contracts");
const { Module } = require("../modules/moduleWrapper");

async function main() {
    let contracts = await loadEssentialContracts({
        wallet: true, 
        market: true,
        userAM: true,
        marketModules: true
    });

    for (let moduleName in contracts.modules) {
        /**
         * @type {Module}
         */
        let module = contracts.modules[moduleName];
        console.log(`Module: ${moduleName}`);
        console.log(await module.getContractAddresses());
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