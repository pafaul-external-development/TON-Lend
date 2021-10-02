const { loadEssentialContracts } = require("../../../utils/contracts");

async function main() {
    let contracts = await loadEssentialContracts({market: true});

    console.log(`Service contract addresses:`);
    console.log(await contracts.marketsAggregator.getServiceContractAddresses());

    console.log(`Known token prices:`);
    console.log(await contracts.marketsAggregator.getTokenPrices());

    console.log(`Market 0 information:`);
    console.log(await contracts.marketsAggregator.getMarketInformation({marketId: 0}));

    console.log(`All markets information:`);
    console.log(await contracts.marketsAggregator.getAllMarkets());

    console.log(`All modules:`);
    console.log(await contracts.marketsAggregator.getAllModules());
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
        process.exit(1);
    }
)