pragma ton-solidity >= 0.39.0;

import "../../utils/libraries/FloatingPointOperations.sol";

library MarketOperations {
    using UFO for uint256;
    using FPO for fraction;

    function calculateU(uint256 totalBorrowed, uint256 realTokens) internal pure returns (fraction) {
        return fraction(totalBorrowed, totalBorrowed + realTokens);
    }

    function calculateBorrowInterestRate(fraction baseRate, fraction u, fraction utilizationMul) internal pure returns (fraction) {
        fraction bir;

        bir = u.fMul(utilizationMul);
        bir = bir.fAdd(baseRate);

        return bir;
    }

    function calculateExchangeRate(uint256 currentPoolBalance, uint256 totalBorrowed, uint256 totalReserve, uint256 vTokenSupply) internal pure returns(fraction) {
        return fraction(currentPoolBalance + totalBorrowed - totalReserve, vTokenSupply);
    }

    function calculateTotalReserve(uint256 totalReserve, uint256 totalBorrowed, fraction r, fraction reserveFactor, uint256 t) internal returns (fraction) {
        fraction tr;
        tr = r.fNumMul(t);
        tr = tr.fMul(reserveFactor);
        tr = tr.fNumMul(totalBorrowed);
        tr = tr.fAddNum(totalReserve);
        return tr;
    }

    function calculateNewIndex(fraction index, fraction bir, uint256 dt) internal returns (fraction) {
        fraction index_;
        index_ = bir.fNumMul(dt);
        index_ = index_.fAddNum(1);
        index_ = index_.fAdd(index);
        return index_;
    }

    function calculateTotalBorrowed(uint256 totalBorrowed, fraction bir, uint256 t) internal returns (uint256) {
        fraction tb_;
        tb_ = bir.fNumMul(t);
        tb_ = tb_.fAddNum(1);
        tb_ = tb_.fNumMul(totalBorrowed);
        return tb_.toNum();
    }

    function calculateReserves(uint256 reserve, uint256 totalBorrowed, fraction bir, fraction reserveFactor, uint256 dt) internal pure returns (uint256) {
        fraction res = bir;
        res = res.fNumMul(dt);
        res = res.fMul(reserveFactor);
        res = res.fNumMul(totalBorrowed);
        res = res.fNumAdd(reserve);
        return res.toNum();
    }
}