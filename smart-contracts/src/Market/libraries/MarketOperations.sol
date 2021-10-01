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
        fraction _mul = mul.fDiv(kink);
        if (kink.isLarger(u)) {
            r = baseRate.fAdd(u.fMul(_mul));
        } else {
            fraction tmp = kink.fMul(_mul);
            tmp = tmp.fAdd(tmp);
            fraction tmp_ = u.fAdd(kink);
            tmp_ = tmp_.fMul(jumpMul);
            r = tmp.fAdd(tmp_);
        }

        return r;
    }

    function calculateTotalReserve(uint256 totalReserve, uint256 totalBorrowed, fraction r, fraction reserveFactor, uint256 t) internal returns (fraction) {
        fraction tr;
        tr = r.fNumMul(t);
        tr = tr.fMul(reserveFactor);
        tr = tr.fNumMul(totalBorrowed);
        tr = tr.fAddNum(totalReserve);
        return tr;
    }

    function calculateIndex(fraction index, fraction r, uint256 t) internal returns (fraction) {
        fraction index_;
        index_ = r.fNumMul(t);
        index_ = index_.fAddNum(1);
        index_ = index_.fAdd(index);
        return index_;
    }

    function calculateTotalBorrowed(uint256 totalBorrowed, fraction r, uint256 t) internal returns (fraction) {
        fraction tb_;
        tb_ = r.fNumMul(t);
        tb_ = tb_.fAddNum(1);
        tb_ = tb_.fNumMul(totalBorrowed);
        return tb_;
    }
}