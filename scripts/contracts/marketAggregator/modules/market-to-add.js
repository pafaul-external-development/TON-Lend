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
            _baseRate: fraction(2, 100 * (365*24*60*60)),
            _utilizationMultiplier: fraction(20, 100 * (365*24*60*60)),
            _reserveFactor: fraction(15, 100),
            _exchangeRate: fraction(1, 1),
            _collateralFactor: fraction(90, 100),
            _liquidationMultiplier: fraction(108, 100)
        }, {
            marketId: 1,
            realToken: '0:22ddfb9bbbdfc307c25ae0460ce644bf9d63cd118a6167bd8193d7ae876a6870',
            _baseRate: fraction(2, 100 * (365*24*60*60)),
            _utilizationMultiplier: fraction(20, 100 * (365*24*60*60)),
            _reserveFactor: fraction(30, 100),
            _exchangeRate: fraction(1, 1),
            _collateralFactor: fraction(25, 100),
            _liquidationMultiplier: fraction(108, 100)
        }]
    } else if (configuration.network == 'local') {
        return [{
            marketId: 0,
            realToken: '0:4c5e140ec14fbbd394232568af191b756970bf36b30600e397b30b3e70b0b7b5',
            _baseRate: fraction(5, 100 * (365*24*60*60)),
            _utilizationMultiplier: fraction(2, 1 * (365*24*60*60)),
            _reserveFactor: fraction(2, 100),
            _exchangeRate: fraction(1, 1),
            _collateralFactor: fraction(30, 100),
            _liquidationMultiplier: fraction(105, 100)
        }, {
            marketId: 1,
            realToken: '0:31f9de039b534e67db86186bc44b35c4cf64a3e577ff1aef52447233ddb85ee7',
            _baseRate: fraction(10, 100 * (365*24*60*60)),
            _utilizationMultiplier: fraction(2, 1 * (365*24*60*60)),
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