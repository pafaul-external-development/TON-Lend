const { fraction } = require("../../../utils/common");

const marketToAdd = {
    marketId: 0,
    realToken: '0:f8790386f28a78b95e175934d540c03ce9f6fa206e4e6357c1baf1ea003e6091',
    initialBalance: 100e9,
    _reserveFactor: fraction(1, 100),
    _kink: fraction(20, 100),
    _collateral: fraction(50, 100),
    _baseRate: fraction(20, 100),
    _mul: fraction(110, 100),
    _jumpMul: fraction(110, 100)
}

module.exports = marketToAdd;