pragma ton-solidity >= 0.47.0;

import './interfaces/IModule.sol';

contract LiquidationModule is ACModule, ILiquidationModule, IUpgradableContract {
    using FPO for fraction;
    using UFO for uint256;

    event TokensLiquidated(uint32 marketId, MarketDelta marketDelta1, uint32 marketToLiquidate, MarketDelta marketDelta2, address liquidator, address targetUser, uint256 tokensLiquidated, uint256 vTokensSeized);

    constructor(address _owner) public {
        tvm.accept();
        owner = _owner;
        actionId = OperationCodes.LIQUIDATE_TOKENS;
    }

    function upgradeContractCode(TvmCell code, TvmCell updateParams, uint32 codeVersion) external override onlyOwner {
        tvm.rawReserve(msg.value, 2);

        tvm.setcode(code);
        tvm.setCurrentCode(code);

        onCodeUpgrade (
            owner,
            marketAddress,
            userAccountManager,
            marketInfo,
            tokenPrices,
            codeVersion
        );
    }

    function onCodeUpgrade(
        address _owner,
        address _marketAddress,
        address _userAccountManager,
        mapping(uint32 => MarketInfo) _marketInfo,
        mapping(address => fraction) _tokenPrices,
        uint32 _codeVersion
    ) private {
        tvm.accept();
        tvm.resetStorage();
        owner = _owner;
        marketAddress = _marketAddress;
        userAccountManager = _userAccountManager;
        marketInfo = _marketInfo;
        tokenPrices = _tokenPrices;
        contractCodeVersion = _codeVersion;
    }

    function performAction(uint32 marketId, TvmCell args, mapping (uint32 => MarketInfo) _marketInfo, mapping (address => fraction) _tokenPrices) external override onlyMarket {
        tvm.rawReserve(msg.value, 2);
        marketInfo = _marketInfo;
        tokenPrices = _tokenPrices;
        TvmSlice ts = args.toSlice();
        (address tonWallet, address targetUser, address tip3UserWallet) = ts.decode(address, address, address);
        TvmSlice amountTS = ts.loadRefAsSlice();
        (uint32 marketToLiquidate, uint256 tokenAmount) = amountTS.decode(uint32, uint256);
        mapping(uint32 => fraction) updatedIndexes = _createUpdatedIndexes();
        IUAMUserAccount(userAccountManager).requestLiquidationInformation{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, targetUser, tip3UserWallet, marketId, marketToLiquidate, tokenAmount, updatedIndexes);
    }

    function liquidate(
        address tonWallet, 
        address targetUser, 
        address tip3UserWallet, 
        uint32 marketId, 
        uint32 marketToLiquidate,
        uint256 tokensProvided, 
        mapping(uint32 => uint256) supplyInfo, 
        mapping(uint32 => BorrowInfo) borrowInfo
    ) external override onlyUserAccountManager {
        tvm.rawReserve(msg.value, 2);
        // Liquidation:
        // 1. Calculate user account health to check if liquidation is required
        // 2. Calculate max values
        // 3. Choose minimal value of all max values
        // 4. Based on min value calculate rest of parameters, it is guaranteed that:
        // - User will not exceed tokens that he provided for liquidation (providingLimit)
        // - User will not exceed tokens that are available for liquidation (borrowLimit)
        // - User will not exceed vToken balance of user that is liquidated (vTokenLimit)

        fraction health = Utilities.calculateSupplyBorrow(supplyInfo, borrowInfo, marketInfo, tokenPrices);
        if (health.nom < health.denom) {
            uint256 maxTokensForLiquidation = borrowInfo[marketToLiquidate].tokensBorrowed;

            fraction fmaxTokensForLiquidationVTokenBased = supplyInfo[marketId].numFMul(marketInfo[marketId].exchangeRate);
            uint256 maxTokensForLiquidationVTokenBased = fmaxTokensForLiquidationVTokenBased.toNum();

            fraction fmaxTokensForLiquidationProvided = tokensProvided.numFMul(marketInfo[marketId].liquidationMultiplier);
            uint256 maxTokensForLiquidationProvided = fmaxTokensForLiquidationProvided.toNum();

            uint256 tokensToLiquidate = math.min(
                maxTokensForLiquidation,
                maxTokensForLiquidationVTokenBased,
                maxTokensForLiquidationProvided
            );

            fraction ftokensToUseForLiquidation = tokensToLiquidate.numFDiv(marketInfo[marketId].liquidationMultiplier);
            uint256 tokensToUseForLiquidation = ftokensToUseForLiquidation.toNum();
            
            fraction ftokensToSeize = tokensToLiquidate.numFDiv(marketInfo[marketId].exchangeRate);
            uint256 tokensToSeize = ftokensToSeize.toNum();

            uint256 tokensToReturn = tokensProvided - tokensToUseForLiquidation;

            BorrowInfo userBorrowInfo = BorrowInfo(borrowInfo[marketToLiquidate].tokensBorrowed - tokensToLiquidate, marketInfo[marketToLiquidate].index);

            MarketDelta marketDelta1;
            MarketDelta marketDelta2;
            mapping(uint32 => MarketDelta) marketDeltas;
            marketDelta1.realTokenBalance.delta = tokensToUseForLiquidation;
            marketDelta1.realTokenBalance.positive = true;
            
            marketDelta2.totalBorrowed.delta = tokensToLiquidate;
            marketDelta2.totalBorrowed.positive = false;

            marketDeltas[marketId] = marketDelta1;
            marketDeltas[marketToLiquidate] = marketDelta2;

            emit TokensLiquidated(marketId, marketDelta2, marketToLiquidate, marketDelta1, tonWallet, targetUser, tokensToLiquidate, tokensToSeize);

            TvmBuilder tb;
            TvmBuilder addressStorage;
            addressStorage.store(tonWallet);
            addressStorage.store(targetUser);
            addressStorage.store(tip3UserWallet);
            TvmBuilder valueStorage;
            valueStorage.store(marketId);
            valueStorage.store(marketToLiquidate);
            valueStorage.store(tokensToSeize);
            valueStorage.store(tokensToReturn);
            TvmBuilder borrowInfoStorage;
            borrowInfoStorage.store(userBorrowInfo);
            tb.store(addressStorage.toCell());
            tb.store(valueStorage.toCell());
            tb.store(borrowInfoStorage.toCell());

            IContractStateCacheRoot(marketAddress).receiveCacheDelta{
                flag: MsgFlag.REMAINING_GAS
            }(marketDeltas, tb.toCell());
        } else {
            IUAMUserAccount(userAccountManager).abortLiquidation{
                flag: MsgFlag.REMAINING_GAS
            }(
                tonWallet,
                targetUser,
                tip3UserWallet, 
                marketId, 
                tokensProvided
            )
        }
    }

    function resumeOperation(TvmCell args, mapping(uint32 => MarketInfo) _marketInfo, mapping (address => fraction) _tokenPrices) external override onlyMarket {
        tvm.rawReserve(msg.value, 2);
        marketInfo = _marketInfo;
        tokenPrices = _tokenPrices;
        TvmSlice ts = args.toSlice();
        TvmSlice addressStorage = ts.loadRefAsSlice();
        (address tonWallet, address targetUser, address tip3UserWallet) = addressStorage.decode(address, address, address);
        TvmSlice valueStorage = ts.loadRefAsSlice();
        (uint32 marketId, uint32 marketToLiquidate, uint256 tokensToSeize, uint256 tokensToReturn) = valueStorage.decode(uint32, uint32, uint256, uint256);
        TvmSlice borrowInfoStorage = ts.loadRefAsSlice();
        (BorrowInfo borrowInfo) = borrowInfoStorage.decode(BorrowInfo);
        IUAMUserAccount(userAccountManager).seizeTokens{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, targetUser, tip3UserWallet, marketId, marketToLiquidate, tokensToSeize, tokensToReturn, borrowInfo);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyUserAccountManager() {
        require(msg.sender == userAccountManager);
        _;
    }

    modifier onlyMarket() {
        require(msg.sender == marketAddress);
        tvm.rawReserve(msg.value, 2);
        _;
    }
}