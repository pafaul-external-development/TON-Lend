const configuration = require("../../../scripts.conf");
const { loadEssentialContracts } = require("../../../utils/contracts");
const {userCodeToUpload} = require("../modules/config");

async function main() {
    let contracts = await loadEssentialContracts({
        wallet: true,
        userAM: true
    });

    let userAccount = await contracts.locklift.factory.getContract('UserAccount', configuration.buildDirectory);

    userCodeToUpload.code = userAccount.code;
    let codeUploadPayload = await contracts.userAccountManager.uploadUserAccountCode({...userCodeToUpload});

    await contracts.msigWallet.transfer({
        destination: contracts.userAccountManager.address,
        payload: codeUploadPayload
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