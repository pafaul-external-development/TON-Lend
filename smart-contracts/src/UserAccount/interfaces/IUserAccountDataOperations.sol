pragma ton-solidity >= 0.39.0;

interface IUserAccountDataOperations {
    // TODO: определиться с данными, хранимыми в аккаунте пользователя
    function getAllData(TvmCell request) external responsible view returns (TvmCell, bool);
    function getProvideData(TvmCell request) external responsible view returns (TvmCell, bool);
    function getBorrowData(TvmCell request) external responsible view returns (TvmCell, bool);
    function getRepayData(TvmCell request) external responsible view returns (TvmCell, bool);
    function getLiquidationData(TvmCell request) external responsible view returns (TvmCell, bool);

    function writeProvideData(TvmCell data) external responsible returns (TvmCell, bool);
    function writeBorrowData(TvmCell data) external responsible returns (TvmCell, bool);
    function writeRepayData(TvmCell data) external responsible returns (TvmCell, bool);
    function writeLiquidationData(TvmCell data) external responsible returns (TvmCell, bool);
}