pragma ton-solidity >= 0.39.0;

interface IWalletControllerMarketInteractions {
    function transferTokensToWallet(address tokenRoot, address destination, uint128 amount, TvmCell payload, address sendGasTo) external view;
}