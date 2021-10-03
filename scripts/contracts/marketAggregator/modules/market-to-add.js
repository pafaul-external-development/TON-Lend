const { fraction } = require("../../../utils/common");

const marketToAdd = {
    marketId: 0,
    realToken: '0:1fdef7c17afc8ae22a99a2d8e7f95d9c1f8560bbdf88fff5dc9ddc3632934984',
    initialBalance: 100e9,
    _reserveFactor: fraction(1, 100),
    _kink: fraction(20, 100),
    _collateral: fraction(50, 100),
    _baseRate: fraction(20, 100),
    _mul: fraction(110, 100),
    _jumpMul: fraction(110, 100)
}

module.exports = marketToAdd;