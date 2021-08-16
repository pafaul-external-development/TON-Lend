function describeError(err) {
    let description;
    if (err.data) {
        let ec = err.data.exit_code;
        switch (ec) {
            case 100:
                description = 'Message sender is not self';
                break;

            case 101:
                description = 'Message sender is not root';
                break;

            case 102:
                description = 'Message sender is not known';
                break;

            case 103:
                description = 'Message sender is not in creation group';
                break;

            case 110:
                description = 'Contract already exists in contract controller';
                break;

            case 111:
                description = 'Contract does not exits in contract controller';
                break;

            case 112:
                description = 'Invalid contract type';
                break;

            case 120:
                description = 'Message value is too low'
                break;

            case 130:
                description = 'Code version is not updated';
                break;

            default:
                description = JSON.stringify(err, null, '\t');
                break;
        }
    } else {
        description = JSON.stringify(err, null, '\t');
    }

    return description;
}

module.exports = {
    describeError
}