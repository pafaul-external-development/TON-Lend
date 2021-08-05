pragma ton-solidity >= 0.39.0;
pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "../../utils/Dex/IDexPair.sol";

struct MarketPriceInfo {
        address market;
        address swapPair;
        bool isLeft;
        uint256 priceToUSD;
    }

interface IOracleUpdatePrices {
    function externalUpdatePrice(address market, uint256 costToUSD) external;
    function internalUpdatePrice(address market) external;

    function internalGetUpdatedPrice(IDexPairBalances updatedPrice) external;
}