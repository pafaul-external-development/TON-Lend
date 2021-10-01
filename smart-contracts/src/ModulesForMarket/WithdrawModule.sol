pragma ton-solidity >= 0.47.0;

import './interfaces/IModule.sol';

import '../utils/libraries/MsgFlag.sol';

contract WithdrawModule is IModule, IContractStateCache, IContractAddressSG {
    using UFO for uint256;
    using FPO for fraction;

    address marketAddress;
    address userAccountManager;
    address owner;

    mapping (uint32 => MarketInfo) marketInfo;
    mapping (address => fraction) tokenPrices;

    constructor() public {
        tvm.accept();
    }

    function sendActionId() external override view responsible returns(uint8) {
        return {flag: MsgFlag.REMAINING_GAS} OperationCodes.WITHDRAW_TOKENS;
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
        marketInfo = _marketInfo;
        tokenPrices = _tokenPrices;
        tonWallet.transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    function performAction(uint32 marketId, TvmCell args) external override onlyMarket {
        TvmSlice ts = args.toSlice();
        (address tonWallet, address userTip3Wallet, address originalTip3Wallet, uint128 tokensToWithdraw) = ts.decode(address, address, address, uint128);
        mapping(uint32 => fraction) updatedIndexes = _createUpdatedIndexes();
        IUAMUserAccount(userAccountManager).requestWithdrawInfo{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, userTip3Wallet, originalTip3Wallet, uint256(tokensToWithdraw), marketId, updatedIndexes);
    }

    function _createUpdatedIndexes() internal view returns(mapping(uint32 => fraction) updatedIndexes) {
        for ((uint32 marketId, MarketInfo mi): marketInfo) {
            updatedIndexes[marketId] = mi.index;
        }
    }

    function withdrawTokensFromMarket(
        address tonWallet, 
        address userTip3Wallet, 
        address originalTip3Wallet, 
        uint256 tokensToWithdraw, 
        uint32 marketId, 
        mapping(uint32 => uint256) si,
        mapping(uint32 => uint256) bi
    ) external onlyUserAccountManager {
        MarketDelta marketDelta;

        MarketInfo mi = marketInfo[marketId];

        fraction exchangeRate = MarketOperations.calculateExchangeRate({
            currentPoolBalance: mi.currentPoolBalance,
            totalBorrowed: mi.totalBorrowed,
            totalReserve: mi.totalReserve,
            totalSupply: mi.totalSupply
        });

        (uint256 supplySum, uint256 borrowSum) = Utilities.calculateSupplyBorrow(si, bi, marketInfo, tokenPrices);

        fraction fTokensToSend = tokensToWithdraw.numFMul(exchangeRate);
        fTokensToSend = fTokensToSend.fMul(tokenPrices[marketInfo[marketId].token]);
        uint256 tokensToSend = fTokensToSend.toNum();
        if (supplySum > borrowSum) {
            if (supplySum - borrowSum > tokensToSend) {
                fTokensToSend = tokensToWithdraw.numFMul(exchangeRate);
                tokensToSend = fTokensToSend.toNum();

                marketDelta.currentPoolBalance.delta = tokensToSend;
                marketDelta.currentPoolBalance.positive = false;
                marketDelta.totalSupply.delta = tokensToSend;
                marketDelta.totalSupply.positive = false;

                IContractStateCacheRoot(marketAddress).receiveCacheDelta{
                    value: 1 ton
                }(tonWallet, marketDelta);

                IUAMUserAccount(userAccountManager).writeWithdrawInfo{
                    flag: MsgFlag.REMAINING_GAS
                }(tonWallet, userTip3Wallet, marketId, tokensToWithdraw, tokensToSend);
            } else {
                IMarketOperations(marketAddress).transferVTokensBack{
                    flag: MsgFlag.REMAINING_GAS
                }(tonWallet, originalTip3Wallet, marketId, tokensToWithdraw);
            }
        } else {
            IUAMUserAccount(userAccountManager).markForLiquidation{
                flag: MsgFlag.REMAINING_GAS
            }(tonWallet);
        }
    }

    modifier onlyMarket() {
        require(msg.sender == marketAddress);
        tvm.rawReserve(msg.value, 2);
        _;
    }

    modifier onlyUserAccountManager() {
        require(msg.sender == userAccountManager);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}