pragma ton-solidity ^0.39.0;

interface IDexPair {
    struct IDexPairBalances {
        uint128 lp_supply;
        uint128 left_balance;
        uint128 right_balance;
    }
    function getBalances() external view responsible returns (IDexPairBalances);
}