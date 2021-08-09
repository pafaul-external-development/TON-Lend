pragma ton-solidity >= 0.39.0;
pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "../../utils/Dex/IDexPair.sol";

struct MarketPriceInfo {
    address swapPair;
    bool isLeft;
    uint256 priceToUSD;
}

interface IOracleUpdatePrices {
    function externalUpdatePrice(address tokenRoot, uint256 costToUSD) external;
    function internalUpdatePrice(address tokenRoot) external;

    function internalGetUpdatedPrice(IDexPairBalances updatedPrice) external;
}