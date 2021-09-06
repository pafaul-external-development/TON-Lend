pragma ton-solidity >= 0.39.0;

interface IContractControllerRunLocal {
    function createInitialDataForMarket(address tip3Deployer, address walletController, address oracle) external returns (TvmCell);
    function createParamsForMarket() external returns (TvmCell);

    function createInitialDataForOracle(uint256 pubkey, address addr) external returns (TvmCell);
    function createParamsForOracle() external returns (TvmCell);

    function createInitialDataForTIP3Deployer(address ownerAddress_) external returns (TvmCell);
    function createParamsForTIP3Deployer() external returns (TvmCell);

    function createInitialDataForUserAccount(address msigOwner) external returns (TvmCell);
    function createParamsForUserAccount() external returns (TvmCell);

    function createInitialDataForUserAccountManager() external returns (TvmCell);
    function createParamsForUserAccountManager() external returns (TvmCell);

    function createInitialDataForWalletController() external returns (TvmCell);
    function createParamsForWalletController() external returns (TvmCell);
}