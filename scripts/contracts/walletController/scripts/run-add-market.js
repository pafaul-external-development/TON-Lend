const { convertCrystal } = require("locklift/locklift/utils");
const { loadEssentialContracts } = require("../../../utils/contracts");

async function main() {
    let contracts = await loadEssentialContracts({
        wallet: true,
        market: true,
        walletC: true
    });

    let marketInfo = await contracts.marketsAggregator.getMarketInformation({
        marketId: 0
    });

    let addMarketPayload = await contracts.walletController.addMarket({
        marketId: 0,
        realTokenRoot: marketInfo.token,
        virtualTokenRoot: marketInfo.virtualToken
    });

    await contracts.msigWallet.transfer({
        destination: contracts.walletController.address,
        value: convertCrystal(10, 'nano'),
        payload: addMarketPayload
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