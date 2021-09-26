pragma ton-solidity >= 0.47.0;

import './interfaces/IModule.sol';

interface IUAMUserAccount {
    function writeSupplyInfo(address tonWallet, address userTip3Wallet, uint32 marketid, uint256 tokensToSupply, uint256 tokenAmount) external view;

    function requestRepayInfo(address tonWallet, address userTip3Wallet, address originalTip3Wallet, uint256 tokensToWithdraw, uint32 marketId, mapping(uint32 => fraction)) external view;
    function receiveRepayInfo(address tonWallet, address tip3UserWallet, uint256 tokensReceived, uint32 marketId, uint8 loanId, mapping(uint32 => fraction) updatedIndexes) external view;
    function writeRepayInformation(address tonWallet, address userTip3Wallet, uint32 marketId, uint8 loanId, uint256 tokensToReturn, BorrowInfo borrowInfo) external view;

    function requestWithdrawInfo(address tonWallet, address userTip3Wallet, address originalTip3Wallet, uint256 tokensToWithdraw, uint32 marketid) external view;
    function receiveWithdrawInfo(address tonWallet, address userTip3Wallet, address originalTip3Wallet, uint256 tokensToWithdraw, uint32 marketid, mapping(uint32 => uint256) si, mapping(uint32 => uint256) bi) external view;
    function writeWithdrawInfo(address tonWallet, address userTip3Wallet, uint32 marketId, uint256 tokensToWithdraw, uint256 tokensToSend) external view;
    function updateIndexesAndReturnTokens(address tonWallet, address originalTip3Wallet, uint32 marketId, uint256 tokensToWithdraw) external view;
}

contract SupplyModule is IModule, IContractStateCache {

    address marketAddress;
    address userAccountManager;
    address owner;

    mapping (uint32 => MarketInfo) marketInfo;
    mapping (address => fraction) tokenPrices;
    
    constructor(address _owner, address _marketAddress, address _userAccountManager) public {
        tvm.accept();
        owner = _owner;
        marketAddress = _marketAddress;
        userAccountManager = _userAccountManager;
    }

    function updateCache(address tonWallet, mapping (uint32 => MarketInfo) marketInfo_, mapping (address => uint256) tokenPrices_) external onlyMarket {
        marketInfo = marketInfo_;
        tokenPrices = tokenPrices_;
        tonWallet.transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    function performAction(uint32 marketId, TvmCell args) external view onlyMarket {
        TvmSlice ts = args.toSlice();
        (address tonWallet, address userTip3Wallet, uint128 tokenAmount) = args.decode(address, address, uint128);
        (uint256 tokensToSupply, MarketInfo marketDelta) = SupplyTokensLib.calculateSupply(tokenAmount, marketInfo);
        MarketDelta delta;
        delta.currentPoolBalance = tokenAmount;
        delta.totalSupply = tokenAmount;
        IContractStateCacheRoot(marketAddress).receiveCacheDelta{
            value: msg.value/4
        }(delta);

        IUAMUserAccount(userAccountManager).writeSupplyInfo{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, userTip3Wallet, marketId, tokensToSupply, tokenAmount);
    }

    function setMarketAddress(address _marketAddress) external onlyOwner {
        marketAddress = _marketAddress;
    }
    
    function getMarketAddress() external view returns(address) {
        return {flag: MsgFlag.REMAINING_GAS} marketAddress;
    }

    function setUserAccountManagerAddress(address _userAccountManager) external onlyOwner {
        userAccountManager = _userAccountManager;
    }

    function getUserAccountManagerAddress() external view returns(address) {
        return {flag: MsgFlag.REMAINING_GAS} marketAddress;
    }

    modifier onlyMarket() {
        require(msg.sender == marketAddress);
        tvm.rawReserve(msg.value, 2);
        _;
    }

    modifier onlyUserAccountManager() {
        require(msg.sender == userAccountManager);
        tvm.rawReserve(msg.value, 2);
        _;
    }
}