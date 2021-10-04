const { fraction } = require("../../../utils/common");

// 1000000000

const marketToAdd = {
    marketId: 0,
    realToken: '0:6713c872168b18f18fbceb6e47857010cc829f19d06ade1c1cb1a2c04f5dce0f',
    initialBalance: 100e9,
    _reserveFactor: fraction(1, 100),
    _kink: fraction(20, 100),
    _collateral: fraction(50, 100),
    _baseRate: fraction(20, 100),
    _mul: fraction(110, 100),
    _jumpMul: fraction(110, 100)
}

module.exports = marketToAdd;