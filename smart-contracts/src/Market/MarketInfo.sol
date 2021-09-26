pragma ton-solidity >= 0.39.0;

import "../utils/libraries/FloatingPointOperations.sol";

struct MarketInfo {
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

struct DeltaInfo {
    bool positive;
    uint256 delta;
}

struct MarketDelta {
    DeltaInfo currentPoolBalance;
    DeltaInfo totalBorrowed;
    DeltaInfo totalReserve;
    DeltaInfo totalSupply;
}