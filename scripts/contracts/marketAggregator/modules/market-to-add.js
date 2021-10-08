const { fraction } = require("../../../utils/common");

// 1000000000

const marketToAdd = {
    marketId: 0,
    realToken: '0:6713c872168b18f18fbceb6e47857010cc829f19d06ade1c1cb1a2c04f5dce0f',
    _baseRate: fraction(5, 100),
    _utilizationMultiplier: fraction(2, 1),
    _reserveFactor: fraction(2, 100),
    _exchangeRate: fraction(1, 1),
    _collateralFactor: fraction(50, 100),
    _liquidationMultiplier: fraction(105, 100)
}

module.exports = marketToAdd;