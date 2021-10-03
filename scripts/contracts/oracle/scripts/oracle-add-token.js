const { loadEssentialContracts } = require("../../../utils/contracts");
const tokenToAdd = require("../modules/tokenToAdd");

async function main() {
    let contracts = await loadEssentialContracts({
        oracle: true, 
        wallet: true,
        testSP: true
    });

    tokenToAdd.swapPairAddress = contracts.testSwapPair.address;
    let addPayload = await contracts.oracle.addToken({...tokenToAdd});

    await contracts.msigWallet.transfer({
        destination: contracts.oracle.address,
        payload: addPayload
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