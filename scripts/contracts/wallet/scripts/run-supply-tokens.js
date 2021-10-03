const { loadEssentialContracts } = require("../../../utils/contracts");
const { loadContractData } = require("../../../utils/migration");
const { Tip3Wallet } = require("../modules/tip3WalletWrapper");

async function main() {
    let contracts = await loadEssentialContracts({
        wallet: true,
        walletC: true
    });

    let realTip3 = new Tip3Wallet(await loadContractData(contracts.locklift, 'realTip3'));
    let virtualTip3 = new Tip3Wallet(await loadContractData(contracts.locklift, 'virtualTip3'));

    let supplyPayload = await contracts.walletController.createSupplyPayload({
        userVTokenWallet: virtualTip3.address
    });

    let transferPayload = await realTip3.transfer({
        to: 
    });
}