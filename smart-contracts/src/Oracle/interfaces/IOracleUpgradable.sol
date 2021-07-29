pragma ton-solc ^0.39.0;
pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

interface IOracleUpgradable {
    function upgrade(TvmCell code, uint32 codeVersion) virtual external;
}