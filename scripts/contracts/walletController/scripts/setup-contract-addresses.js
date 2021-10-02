const { convertCrystal } = require("locklift/locklift/utils");
const { loadEssentialContracts, operationFlags } = require("../../../utils/common");

async function main() {
    let contracts = await loadEssentialContracts({
        wallet: true,
        market: true,
        userAM: true
    });

    let marketPayload = await contracts.walletController.setMarketAddress({
        _market: contracts.marketsAggregator.address
    });

    await contracts.msigWallet.transfer({
        destination: contracts.walletController.address,
        value: convertCrystal(1, 'nano'),
        flags: operationFlags.FEE_FROM_CONTRACT_BALANCE,
        bounce: false,
        payload: marketPayload
    });
    
    console.log('Contract addresses for WalletController set');
}

main().then(
    () => process.exit(0)
).catch(
    (err) => {
        console.log(err);
        process.exit(1);
    }
)