pragma ton-solidity >= 0.43.0;

import './IUserAccount.sol';

interface IUAMUserAccount {
    // Supply operation,starts at wallet controller
    function writeSupplyInfo(address tonWallet, uint32 marketId, uint256 tokensToSupply, fraction index) external view;

    // Repay operation,starts at wallet controller
    function requestRepayInfo(address tonWallet, address userTip3Wallet, uint256 tokensForRepay, uint32 marketId, mapping(uint32 => fraction) updatedIndexes) external view;
    function receiveRepayInfo(address tonWallet, address userTip3Wallet, uint256 tokensForRepay, uint32 marketId, BorrowInfo borrowInfo) external view;
    function writeRepayInformation(address tonWallet, address userTip3Wallet, uint32 marketId, uint256 tokensToReturn, BorrowInfo borrowInfo) external view;

    // Withdraw operation,starts at wallet controller
    function requestWithdraw(address tonWallet, address userTip3Wallet, uint32 marketId, uint256 tokensToWithdraw) external view;
    function requestWithdrawInfo(address tonWallet, address userTip3Wallet, uint256 tokensToWithdraw, uint32 marketId, mapping(uint32 => fraction) updatedIndexes) external view;
    function receiveWithdrawInfo(address tonWallet, address userTip3Wallet, uint256 tokensToWithdraw, uint32 marketId, mapping(uint32 => uint256) si, mapping(uint32 => uint256) bi) external view;
    function writeWithdrawInfo(address tonWallet, address userTip3Wallet, uint32 marketId, uint256 tokensToWithdraw, uint256 tokensToSend) external view;

    // Borrow operation, initializes from user account
    function requestIndexUpdate(address tonWallet, uint32 market, TvmCell args) external view;
    function updateUserIndexes(address tonWallet, address userTip3Wallet, uint256 tokensToBorrow, uint32 marketId, mapping(uint32 => fraction) updatedIndexes) external view;
    function passBorrowInformation(address tonWallet, address userTip3Wallet, uint32 marketId, uint256 tokensToBorrow, mapping(uint32 => uint256) supplyInfo, mapping(uint32 => uint256) borrowInfo) external view;
    function writeBorrowInformation(address tonWallet, address userTip3Wallet, uint256 tokensToBorrow, uint32 marketId, fraction index) external view;

    // Check user account health operation
    function requestUserAccountHealthCalculation(address tonWallet) external view;
    function calculateUserAccountHealth(address tonWallet, address gasTo, mapping(uint32 => uint256) supplyInfo, mapping(uint32 => BorrowInfo) borrowInfo) external view;
    function updateUserAccountHealth(address tonWallet, address gasTo, fraction accountHealth, mapping(uint32 => fraction) updatedIndexes) external view;

    // Liquidation operation
    // function requestLiquidationInformation(address tonWallet, address targetUser, address tip3UserWallet, uint32 marketId, uint256 tokensProvided, mapping(uint32 => fraction) updatedIndexes) external view;
    // function receiveLiquidationInformation(address tonWallet, address targetUser, address tip3UserWallet, uint32 marketId, uint256 tokensProvided, mapping(uint32 => uint256) supplyInfo, mapping(uint32 => BorrowInfo) borrowInfo) external view;
    // function liquidateVTokens(address tonWallet, address targetuser, address tip3UserWallet, uint256 tokensProvided, uint256 vTokensToLiquidate, uint256 tokensToReturn) external view;
    // function grantVTokens(address tonWallet, address tip3UserWallet, uint256 vTokensToGrant, uint256 tokensToReturn) external view;
    // function externalHealthUpdate(address tonWallet, address targetuser, address tip3userWallet, uint256 tokensToReturn) external view;

    // Service operations
    function requestTokenPayout(address tonWallet, address userTip3Wallet, uint32 marketId, uint256 tokensToSend) external view;
}
