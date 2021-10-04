pragma ton-solidity >= 0.47.0;

import './interfaces/IModule.sol';

import '../utils/libraries/MsgFlag.sol';

contract RepayModule is IModule, IContractStateCache, IContractAddressSG {
    using UFO for uint256;
    using FPO for fraction;

    address userAccountManager;
    address marketAddress;
    address owner;

    mapping(uint32 => MarketInfo) marketInfo;
    mapping(address => fraction) tokenPrices;


    constructor(address _owner) public {
        tvm.accept();
        owner = _owner;
    }

    function sendActionId() external override view responsible returns(uint8) {
        return {flag: MsgFlag.REMAINING_GAS} OperationCodes.REPAY_TOKENS;
    }

    function setMarketAddress(address _marketAddress) external override onlyOwner {
        tvm.rawReserve(msg.value, 2);
        marketAddress = _marketAddress;
        address(owner).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    function setUserAccountManager(address _userAccountManager) external override onlyOwner {
        tvm.rawReserve(msg.value, 2);
        userAccountManager = _userAccountManager;
        address(owner).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    function getContractAddresses() external override view responsible returns(address _owner, address _marketAddress, address _userAccountManager) {
        return {flag: MsgFlag.REMAINING_GAS} (owner, marketAddress, userAccountManager);
    }

    function updateCache(address tonWallet, mapping(uint32 => MarketInfo) _marketInfo, mapping(address => fraction) _tokenPrices) external override onlyMarket {
        tvm.rawReserve(msg.value , 2);
        marketInfo = _marketInfo;
        tokenPrices = _tokenPrices;
        tonWallet.transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    function performAction(uint32 marketId, TvmCell args) external override onlyMarket {
        tvm.rawReserve(msg.value, 2);
        TvmSlice ts = args.toSlice();
        (address tonWallet, address userTip3Wallet, uint256 tokensReceived, uint8 loanId) = ts.decode(address, address, uint256, uint8);
        mapping(uint32 => fraction) updatedIndexes = _createUpdatedIndexes();

        IUAMUserAccount(userAccountManager).requestRepayInfo{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, userTip3Wallet, tokensReceived, marketId, loanId, updatedIndexes);
    }

    function _createUpdatedIndexes() internal view returns(mapping(uint32 => fraction) updatedIndexes) {
        for ((uint32 marketId, MarketInfo mi): marketInfo) {
            updatedIndexes[marketId] = mi.index;
        }
    }

    function repayLoan(
        address tonWallet,
        address userTip3Wallet,
        uint256 tokensForRepay,
        uint32 marketId,
        uint8 loanId,
        BorrowInfo borrowInfo
    ) external onlyUserAccountManager {
        tvm.rawReserve(msg.value - msg.value / 4, 0);
        MarketDelta marketDelta;

        fraction newRepayInfo = marketInfo[marketId].index.fNumMul(borrowInfo.toRepay);
        newRepayInfo = newRepayInfo.fDiv(borrowInfo.index);
        uint256 tokensToRepay = newRepayInfo.toNum();
        uint256 tokensToReturn;

        uint256 tokenDelta;
        if (tokensToRepay <= tokensForRepay) {
            tokensToReturn = tokensForRepay - tokensToRepay;
            borrowInfo.toRepay = 0;
            tokenDelta = tokensToRepay;
        } else {
            tokensToReturn = 0;
            borrowInfo.toRepay = tokensToRepay - tokensForRepay;
            borrowInfo.index = marketInfo[marketId].index;
        } 

        marketDelta.totalBorrowed.delta = tokenDelta;
        marketDelta.totalBorrowed.positive = false;
        marketDelta.currentPoolBalance.delta = tokenDelta;
        marketDelta.currentPoolBalance.positive = true;

        IContractStateCacheRoot(marketAddress).receiveCacheDelta{
            value: msg.value / 4
        }(tonWallet, marketDelta, marketId);

        IUAMUserAccount(userAccountManager).writeRepayInformation{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, userTip3Wallet, marketId, loanId, tokensToReturn, borrowInfo);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyMarket() {
        require(msg.sender == marketAddress);
        _;
    }

    modifier onlyUserAccountManager() {
        require(msg.sender == userAccountManager);
        _;
    }
}