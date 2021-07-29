pragma ton-solidity ^0.39.0;

interface IUpgradableContract {
    function upgradeContractCode(TvmCell code, uint32 codeVersion, uint8 contractType) virtual external;
}