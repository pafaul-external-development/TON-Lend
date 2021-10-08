const { fraction } = require("../../../utils/common");

// 1000000000

const marketToAdd = {
    marketId: 0,
    realToken: '0:22851129f9d892ea040d8eac15e0cf1568986f01da45e8bac9538b0e0c9e8ba7',
    _baseRate: fraction(5, 100),
    _utilizationMultiplier: fraction(2, 1),
    _reserveFactor: fraction(2, 100),
    _exchangeRate: fraction(1, 1),
    _collateralFactor: fraction(50, 100),
    _liquidationMultiplier: fraction(105, 100)
}

module.exports = marketToAdd;