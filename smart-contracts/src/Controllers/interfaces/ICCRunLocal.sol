pragma ton-solidity >= 0.39.0;

interface IContractControllerRunLocal {
    function createInitialDataForOracle(uint256 pubkey, address addr) external returns(TvmCell);

    function createInitialDataForUserAccountManager() external returns(TvmCell);

    function createInitialDataForWalletController() external returns(TvmCell);
}