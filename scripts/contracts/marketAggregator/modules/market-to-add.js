const { fraction } = require("../../../utils/common");

const marketToAdd = {
    marketId: 0,
    realToken: '0:6c562ae2ade420ae672c007a8d66565a066f7320ac746519420a8e5d5ec6897b',
    initialBalance: 100e9,
    _reserveFactor: fraction(1, 100),
    _kink: fraction(20, 100),
    _collateral: fraction(50, 100),
    _baseRate: fraction(20, 100),
    _mul: fraction(110, 100),
    _jumpMul: fraction(110, 100)
}

module.exports = marketToAdd;