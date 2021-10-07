pragma ton-solidity >= 0.39.0;

import "../utils/libraries/FloatingPointOperations.sol";

struct DeltaInfo {
    bool positive;
    uint256 delta;
}

struct MarketInfo {
    address token;
    uint256 realTokenBalance;
    uint256 vTokenBalance;
    uint256 totalBorrowed;
    uint256 totalReserve;

    fraction index;
    fraction baseRate;
    fraction utilizationMultiplier;
    fraction reserveFactor;
    fraction exchangeRate;
    fraction collateralFactor;

    uint256 lastUpdateTime;
}

struct MarketDelta {
    DeltaInfo realTokenBalance;
    DeltaInfo vTokenBalance;
    DeltaInfo totalBorrowed;
}

struct MarketInfo_ {
    address token;
    address virtualToken;
    uint256 currentPoolBalance;
    uint256 totalBorrowed;
    uint256 totalReserve;
    uint256 totalSupply;
    
    fraction index;
    fraction reserveFactor;
    fraction kink;
    fraction collateral;
    fraction baseRate;
    fraction mul;
    fraction jumpMul;

    uint256 lastUpdateTime;
}

struct MarketDelta_ {
    DeltaInfo currentPoolBalance;
    DeltaInfo totalBorrowed;
    DeltaInfo totalReserve;
    DeltaInfo totalSupply;
}