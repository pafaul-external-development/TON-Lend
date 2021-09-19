pragma ton-solidity >= 0.39.0;

import "../../utils/libraries/FloatingPointOperations.sol";

struct BorrowInfo {
    uint256 toRepay;
    fraction index;
}

struct UserMarketInfo {
    uint32 marketId;
    uint256 suppliedTokens;
    mapping(uint8 => BorrowInfo) borrowInfo;
}

interface IUserAccount {
    function getOwner() external responsible view returns(address);

    function enterMarket(uint32 marketId) external;

    function borrow(uint32 marketId, uint256 amountToBorrow, address userTIP3) external;

    function updateIndexes(uint32 marketId_, mapping(uint32 => fraction) newIndexes, address userTip3Wallet, uint256 toBorrow) external;
}

library UserAccountConstants {
    uint8 constant MAX_BORROWS_PER_MARKET = 8;
}

library ManageMapping {
    function removeItemFrom(mapping(uint8 => BorrowInfo) value, uint8 index) internal pure {
        optional(uint8, BorrowInfo) maxItem = value.max();
        if (!maxItem.hasValue()) {
            return;
        }
        (uint8 key, ) = maxItem.get();
        if (key == 0) {
            delete value[0];
            return;
        }

        value[index] = value[key];
        delete value[key];
    }

    function getMaxItem(mapping(uint8 => BorrowInfo) value) internal pure returns (uint8) {
        optional(uint8, BorrowInfo) maxItem = value.max();
        if (!maxItem.hasValue()) {
            return 0;
        }
        (uint8 maxIndex, ) = maxItem.get();
        return maxIndex + 1;
    }
}