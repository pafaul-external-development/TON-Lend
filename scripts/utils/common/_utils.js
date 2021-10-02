function describeTransaction(tx) {
    let description = '';
    description += `Tx ${tx.compute.success == true ? 'success':'fail'}\n`;
    description += `Fees: ${tx.fees.total_account_fees}`;
    return description;
}

function pp(obj) {
    return JSON.stringify(obj, null, '\t');
}

const stringToBytesArray = (dataString) => {
    return Buffer.from(dataString).toString('hex')
};

module.exports = {
    describeTransaction,
    stringToBytesArray,
    pp
}