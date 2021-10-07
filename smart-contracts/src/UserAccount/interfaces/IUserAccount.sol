pragma ton-solidity >= 0.43.0;

import "../../utils/libraries/FloatingPointOperations.sol";

struct BorrowInfo {
    uint256 tokensBorrowed;
    fraction index;
}

struct UserMarketInfo {
    bool exists;
    uint32 _marketId;
    uint256 suppliedTokens;
    fraction accountHealth;
    BorrowInfo borrowInfo;
}

interface IUserAccount {
    function getOwner() external responsible view returns(address);

    function enterMarket(uint32 marketId) external;

    function borrow(uint32 marketId, uint256 amountToBorrow, address userTip3Wallet) external;

    function withdrawExtraTons() external view;
}

interface IUserAccountData {
    function writeSupplyInfo(uint32 marketId_, uint256 tokensToSupply, fraction index) external;

    function borrowUpdateIndexes(uint32 marketId_, mapping(uint32 => fraction) newIndexes, address userTip3Wallet, uint256 toBorrow) external;
    function writeBorrowInformation(uint32 marketId_, uint256 toBorrow, address userTip3Wallet, fraction marketIndex) external;

    function sendRepayInfo(address userTip3Wallet, uint32 marketId, uint256 tokensForRepay, mapping(uint32 => fraction) updatedIndexes) external;
    function writeRepayInformation(address userTip3Wallet, uint32 marketId_, uint256 tokensToReturn, BorrowInfo bi) external;

    function writeWithdrawInfo(address userTip3Wallet, uint32 marketId, uint256 tokensToWithdraw, uint256 tokensToSend) external;
    function requestWithdrawInfo(address userTip3Wallet, uint32 marketId, uint256 tokensToWithdraw, mapping(uint32 => fraction) updatedIndexes) external;

    function checkUserAccountHealth() external;
    function updateUserAccountHealth(fraction _accountHealth, mapping(uint32 => fraction) updatedIndexes) external;
}

interface IUserAccountGetters {
    function getKnownMarkets() external view responsible returns(mapping(uint32 => bool));
    function getMarketInfo(uint32 marketId) external view responsible returns(UserMarketInfo);
    function getAllMarketsInfo() external view responsible returns(mapping(uint32 => UserMarketInfo));
}