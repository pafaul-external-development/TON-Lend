pragma ton-solidity ^0.39.0;
pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "../../utils/IDexPair.sol";

interface IOracleUpdatePrices {
    struct MarketPriceInfo {
        address market;
        address swapPair;
        bool isLeft;
        uint256 priceToUSD;
    }

    function externalUpdatePrice(address market, uint256 costToUSD) virtual external;
    function internalUpdatePrice(address market) virtual external;
    function internalFullUpdate() virtual external;

    function internalGetUpdatedPrice(IDexPairBalances updatedPrice) virtual external;
}