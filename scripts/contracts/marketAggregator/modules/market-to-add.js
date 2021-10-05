const { fraction } = require("../../../utils/common");

// 1000000000

const marketToAdd = {
    marketId: 0,
    realToken: '0:22851129f9d892ea040d8eac15e0cf1568986f01da45e8bac9538b0e0c9e8ba7',
    initialBalance: 100e9,
    _reserveFactor: fraction(1, 100),
    _kink: fraction(20, 100),
    _collateral: fraction(50, 100),
    _baseRate: fraction(20, 100),
    _mul: fraction(110, 100),
    _jumpMul: fraction(110, 100)
}

module.exports = marketToAdd;