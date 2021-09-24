pragma ton-solidity >= 0.39.0;

struct fraction {
    uint256 nom;
    uint256 denom;
}

library FPO {
    function fMul(fraction a, fraction b) internal pure returns (fraction) {
        return fraction(a.nom*b.nom, a.denom*b.denom);
    }

    function fNumMul(fraction a, uint256 b) internal pure returns (fraction) {
        return fraction(a.nom * b, a.denom);
    }

    function fNumDiv(fraction a, uint256 b) internal pure returns (fraction) {
        return fraction(a.nom, a.denom * b);
    }

    function fDiv(fraction a, fraction b) internal pure returns(fraction) {
        return fraction(a.nom * b.denom, a.denom * b.nom);
    }

    function fAdd(fraction a, fraction b) internal pure returns (fraction) {
        return fraction (a.nom * b.denom + b.nom * a.denom, a.denom * b.denom);
    }

    function fAddNum(fraction a, uint256 b) internal pure returns (fraction) {
        return fraction (a.nom + b*a.denom, a.denom);
    }

    function fSub(fraction a, fraction b) internal pure returns (fraction) {
        return fraction(a.nom * b.denom - b.nom * a.denom, a.denom * b.denom);
    }

    function isLarger(fraction a, fraction b) internal pure returns (bool) {
        return a.nom * b.denom > b.nom * a.denom;
    }

    function toNum(fraction a) internal pure returns(uint256) {
        return a.nom / a.denom;
    }
}

library UFO {
    function numMul(uint256 a, fraction b) internal pure returns (uint256) {
        return a*b.nom/b.denom;
    }

    function numFMul(uint256 a, fraction b) internal pure returns (fraction) {
        return fraction(a * b.nom, b.denom);
    }

    function numFDiv(uint256 a, fraction b) internal pure returns (fraction) {
        return fraction(a * b.denom, b.nom);
    }

    function numAdd(uint256 a, fraction b) internal pure returns (uint256) {
        return (a*b.denom + b.nom) / b.denom;
    }

    function numSub(uint256 a, fraction b) internal pure returns (uint256) {
        return (a * b.denom - b.nom)/b.denom;
    }

    function toF(uint256 num) internal pure returns(fraction) {
        return fraction(num, 1);
    }
}