pragma ton-solidity >= 0.43.0;

import './IUserAccount.sol';

interface IUAMUserAccount {
    function enterMarket(address tonWallet, uint32 marketId) external view responsible returns (address);

    function writeSupplyInfo(address tonWallet, address userTip3Wallet, uint32 marketId_, uint256 tokensToSupply, fraction index) external view;
    function requestVTokenMint(address tonWallet, address userTip3Wallet, uint32 marketId_, uint256 toMint) external view;

    function updateUserIndex(address tonWallet, uint32 marketId, mapping(uint32 => fraction) updatedIndexes, address userTip3Wallet, uint256 toBorrow) external view;
    function writeBorrowInformation(address tonWallet, uint32 marketId_, uint256 toBorrow, address userTip3Wallet, fraction marketIndex) external view;

    function requestRepayInfo(address tonWallet, address userTip3Wallet, uint32 marketId_, uint8 loanId, uint256 tokensToPayout) external view;
    function writeRepayInformation(address tonWallet, address userTip3Wallet, uint32 marketId_, uint8 loanId, uint256 tokensToReturn, BorrowInfo bi) external view;
    function requestTokenPayout(address tonWallet, address userTip3Wallet, uint32 marketId_, uint256 tokensToSendBack) external view;

    function requestIndexUpdate(address tonWallet, uint32 marketId, mapping(uint32 => bool) knownMarkets, address userTip3Wallet, uint256 amountToBorrow) external view;
    function passBorrowInformation(address tonWallet, address userTip3Wallet, uint32 marketId, uint256 toBorrow, mapping(uint32 => uint256) borrowInfo, mapping(uint32 => uint256) supplyInfo) external view;
    function sendRepayInfo(address tonWallet, address userTip3Wallet, uint32 marketId, uint8 loanId, uint256 tokensForRepay, BorrowInfo bi) external view;

    function requestWithdrawInfo(address tonWallet, address userTip3Wallet, address originalTip3Wallet, uint32 marketId, uint256 tokensToWithdraw) external view;
    function passWithdrawInfo(address tonWallet, address userTip3Wallet, address originalTip3Wallet, uint32 marketId, uint256 tokensToWithdraw, mapping(uint32 => uint256) si, mapping(uint32 => uint256) bi) external view;
    function writeWithdrawInfo(address tonWallet, address userTip3Wallet, uint32 marketId, uint256 tokensToWithdraw, uint256 tokensToSend, mapping(uint32 => fraction) updatedIndexes) external view;
    function updateIndexesAndReturnTokens(address tonWallet, address originalTip3Wallet, uint32 marketId, uint256 tokensToWithdraw, mapping(uint32 => fraction) updatedIndexes) external view;
    function transferVTokensBack(address tonWallet, address userTip3Wallet, uint32 marketId, uint256 tokensToReturn) external view;

    function writeSupplyInfoSync(address tonWallet, uint32 marketId_, uint256 tokensToSupply, fraction index) external view responsible returns(bool);
    function requestWithdrawInfoSync(address tonWallet) external view responsible returns(mapping(uint32 => uint256), mapping(uint32 => uint256));
    function requestIndexUpdateSync(address tonWallet) external view responsible returns(mapping(uint32 => uint256), mapping(uint32 => uint256));
    function writeBorrowInformationSync(address tonWallet, uint32 marketId_, uint256 toBorrow, address userTip3Wallet, fraction marketIndex) external view responsible returns(bool);
    function writeWithdrawInfoSync(address tonWallet, address userTip3Wallet, uint32 marketId, uint256 tokensToWithdraw, uint256 tokensToSend, mapping(uint32 => fraction) updatedIndexes) external view responsible returns(bool);
    function updateIndexesAndReturnTokensSync(address tonWallet, address originalTip3Wallet, uint32 marketId, uint256 tokensToWithdraw, mapping(uint32 => fraction) updatedIndexes) external view responsible returns(bool);
    function updateUserIndexSync(address tonWallet, uint32 marketId, mapping(uint32 => fraction) updatedIndexes, address userTip3Wallet, uint256 toBorrow) external view responsible returns(mapping(uint32 => uint256), mapping(uint32 => uint256));
    function requestRepayInfoSync(address tonWallet, address userTip3Wallet, uint32 marketId_, uint8 loanId, uint256 tokensToPayout) external view responsible returns(BorrowInfo bi);
}