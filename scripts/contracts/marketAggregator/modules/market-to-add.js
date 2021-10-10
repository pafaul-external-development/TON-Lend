const configuration = require("../../../scripts.conf");
const { fraction } = require("../../../utils/common");

// 1000000000

/**
 * @typedef MarketParams
 * @type {Object}
 * @property {Number} marketId
 * @property {String} realToken
 * @property {import("./marketsAggregatorWrapper").Fraction} _baseRate
 * @property {import("./marketsAggregatorWrapper").Fraction} _utilizationMultiplier
 * @property {import("./marketsAggregatorWrapper").Fraction} _reserveFactor
 * @property {import("./marketsAggregatorWrapper").Fraction} _exchangeRate
 * @property {import("./marketsAggregatorWrapper").Fraction} _collateralFactor
 * @property {import("./marketsAggregatorWrapper").Fraction} _liquidationMultiplier
 */

/**
 * 
 * @returns {MarketParams[]}
 */
function marketsToAdd() {
    if (configuration.network == 'devnet') {
        return [{
            marketId: 0,
            realToken: '0:22851129f9d892ea040d8eac15e0cf1568986f01da45e8bac9538b0e0c9e8ba7',
            _baseRate: fraction(5, 100),
            _utilizationMultiplier: fraction(2, 1),
            _reserveFactor: fraction(2, 100),
            _exchangeRate: fraction(1, 1),
            _collateralFactor: fraction(50, 100),
            _liquidationMultiplier: fraction(105, 100)
        }]
    } else if (configuration.network == 'local') {
        return [{
            marketId: 0,
            realToken: '0:6713c872168b18f18fbceb6e47857010cc829f19d06ade1c1cb1a2c04f5dce0f',
            _baseRate: fraction(5, 100),
            _utilizationMultiplier: fraction(2, 1),
            _reserveFactor: fraction(2, 100),
            _exchangeRate: fraction(1, 1),
            _collateralFactor: fraction(30, 100),
            _liquidationMultiplier: fraction(105, 100)
        }, {
            marketId: 1,
            realToken: '0:e095d20f15876dbdb73b0651f3443a74c811d5d3a3b435a85f0b8a95cb31e4e6',
            _baseRate: fraction(10, 100),
            _utilizationMultiplier: fraction(2, 1),
            _reserveFactor: fraction(2, 100),
            _exchangeRate: fraction(10, 1),
            _collateralFactor: fraction(30, 100),
            _liquidationMultiplier: fraction(105, 100)
        }]
    }
}

module.exports = {
    marketsToAdd
};