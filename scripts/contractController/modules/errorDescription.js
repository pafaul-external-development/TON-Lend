function describeError(err) {
    let ec = err.data.exit_code;
    if (ec == 110) {
        return "Contract already exists in contract controller";
    }

    if (ec == 111) {
        return "Contract does not exits in contract controller";
    }

    if (ec == 120) {
        return "Message value is too low";
    }

    return JSON.stringify(err, null, '\t');
}

module.exports = {
    describeError
}