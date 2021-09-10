pragma ton-solidity >= 0.39.0;

import "../../utils/libraries/FloatingPointOperations.sol";

library MarketOperations {
    using UFO for uint256;
    using FPO for fraction;

    function calculateU(uint256 totalBorrowed, uint256 currentPoolBalance) internal pure returns(fraction) {
        return fraction(totalBorrowed, totalBorrowed * currentPoolBalance);
    }

    function calculateExchangeRate(uint256 currentPoolBalance, uint256 totalBorrowed, uint256 totalReserve, uint256 totalSupply) internal pure returns(fraction) {
        return fraction(currentPoolBalance + totalBorrowed - totalReserve, totalSupply);
    }

    function calculateR(fraction u, fraction baseRate, fraction mul, fraction kink, fraction jumpMul) internal returns (fraction) {
        fraction r;
        fraction mul_ = mul.fDiv(kink);
        if (kink.isLarger(u)) {
            r = baseRate.fAdd(u.fMul(mul_));
        } else {
            fraction tmp = kink.fMul(mul_);
            tmp = tmp.fAdd(tmp);
            fraction tmp_ = u.fAdd(kink);
            tmp_ = tmp_.fMul(jumpMul);
            r = tmp.fAdd(tmp_);
        }

        return r;
    }

    function calculateTotalReserve(uint256 totalReserve, uint256 totalBorrowed, fraction r, fraction reserveFactor, uint256 t) internal returns (fraction) {
        fraction tr;
        tr = r.fMulNum(t);
        tr = tr.fMul(reserveFactor);
        tr = tr.fMulNum(totalBorrowed);
        tr = tr.fAddNum(totalReserve);
        return tr;
    }

    function calculateIndex(fraction index, fraction r, uint256 t) internal returns (fraction) {
        fraction index_;
        index_ = r.fMulNum(t);
        index_ = index_.fAddNum(1);
        index_ = index_.fAdd(index);
        return index_;
    }

    function calculateTotalBorrowed(fraction totalBorrowed, fraction r, uint256 t) internal returns (fraction) {
        fraction tb_;
        tb_ = r.fMulNum(t);
        tb_ = tb_.fAddNum(1);
        tb_ = tb_.fMul(totalBorrowed);
        return tb_;
    }
}