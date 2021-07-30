pragma ton-solidity >= 0.39.0;
pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

interface IOracleManageMarkets {
    function addMarket(address market, address swapPairAddress, bool isLeft) external;
    function removeMarket(address market) external;
}