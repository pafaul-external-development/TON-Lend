pragma ton-solidity >= 0.39.0;

interface ICCMarketDeployed {
    function marketDeployed(address realTokenRoot, address virtualTokenRoot) external;
}