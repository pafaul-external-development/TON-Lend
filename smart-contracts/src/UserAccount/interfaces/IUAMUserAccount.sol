pragma ton-solidity >= 0.43.0;

import "./IUserAccount.sol";

interface IUAMUserAccount {
    function enterMarket(address tonWallet, uint32 marketId) external view responsible returns (address);
    function fetchInformationFromUserAccount(address tonWallet, TvmCell payload) external view;
    function passInformationToMarket(address tonWallet, TvmCell payload) external view;
    function writeInformationToUserAccount(address tonWallet, TvmCell payload) external view;

    function writeSupplyInfo(address tonWallet, uint32 marketId_, uint256 tokensToSupply) external view;

    function updateUserIndex(address tonWallet, uint32 marketId_, mapping(uint32 => fraction) updatedIndexes, address tip3UserWallet, uint256 amountToBorrow) external view;
    function writeBorrowInformation(address tonWallet, uint32 marketId_, uint256 toBorrow, address userTip3Wallet, fraction marketIndex) external view;
    function requestBorrowSend(address tonWallet, address userTip3Wallet, uint32 marketId_, uint256 toSend) external view;

    function requestRepayInfo(address tonWallet, uint32 marketId_, uint8 loanId, uint256 tokensToPayout) external view;
    function writeRepayInformation(address tonWallet, uint32 marketId_, address userTip3Wallet, uint256 tokensToReturn, BorrowInfo bi) external view;
    function repaySendTokensBack(address tonWallet, address userTip3Wallet, uint32 marketId_, uint256 tokensToSendBack) external view;
}