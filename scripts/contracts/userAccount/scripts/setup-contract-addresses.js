const { loadEssentialContracts } = require("../../../utils/common");

async function main() {
    let contracts = await loadEssentialContracts({
        wallet: true,
        market: true,
        userAM: true,
        marketModules: true
    });

    let marketPayload = await contracts.userAccountManager.setMarketAddress({
        _market: contracts.marketsAggregator.address
    });

    await contracts.msigWallet.transfer({
        destination: contracts.userAccountManager.address,
        value: convertCrystal(1, 'nano'),
        flags: operationFlags.FEE_FROM_CONTRACT_BALANCE,
        bounce: false,
        payload: marketPayload
    });

    console.log(`MarketsAggregator service address setup finished`);

    for (let moduleName of contracts.modules) {
        /**
         * @type {Module}
         */
        let module = contracts.modules[moduleName];

        let operationId = await module.sendActionId({});

        let modulePayload = await contracts.userAccountManager.addModule({
            operationId,
            module: module.address
        });

        await contracts.msigWallet.transfer({
            destination: contracts.userAccountManager.address,
            value: convertCrystal(1, 'nano'),
            flag: operationFlags.FEE_FROM_CONTRACT_BALANCE,
            bounce: false,
            payload: modulePayload
        });
    }

    console.log('Modules for markets are set up');
}

main().then(
 () => process.exit(0)
).catch(
 (err) => {
     console.log(err);
     process.exit(1);
 }
)