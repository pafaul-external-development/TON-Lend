pragma ton-solidity >= 0.39.0;


struct MarketInfo {
    address token;
    address virtualToken;
    uint32 kinkNominator;
    uint32 kinkDenominator;
    uint32 collateralFactorNominator;
    uint32 collateralFactorDenominator;
}