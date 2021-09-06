pragma ton-solidity >= 0.39.0;

interface ICCMarketDeployed {
    function marketDeployed(uint32 marketId, address realTokenRoot, address virtualTokenRoot) external;
}