pragma ton-solidity >= 0.47.0;

import './interfaces/IModule.sol';

contract BorrowModule is IModule, IContractStateCache, IContractAddressSG, IBorrowModule, IUpgradableContract {
    using FPO for fraction;
    using UFO for uint256;

    address owner;
    address marketAddress;
    address userAccountManager;
    uint32 public contractCodeVersion;

    mapping (uint32 => MarketInfo) marketInfo;
    mapping (address => fraction) tokenPrices;

    event TokenBorrow(uint32 marketId, MarketDelta marketDelta, address tonWallet, uint256 tokensToBorrow);

    constructor(address _owner) public {
        tvm.accept();
        owner = _owner;
    }

    function upgradeContractCode(TvmCell code, TvmCell updateParams, uint32 codeVersion) external override onlyOwner {
        tvm.rawReserve(msg.value, 2);

        address _owner = owner;
        address _marketAddress = marketAddress;
        address _userAccountManager = userAccountManager;
        mapping(uint32 => MarketInfo) _marketInfo = marketInfo;
        mapping(address => fraction) _tokenPrices = tokenPrices;

        tvm.setcode(code);
        tvm.setCurrentCode(code);

        onCodeUpgrade (
            _owner,
            _marketAddress,
            _userAccountManager,
            _marketInfo,
            _tokenPrices,
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
        userAccountManager = _userAccountManager;
        contractCodeVersion = _codeVersion;
    }

    function sendActionId() external override view responsible returns(uint8) {
        return {flag: MsgFlag.REMAINING_GAS} OperationCodes.BORROW_TOKENS;
    }

    function getModuleState() external override view returns(mapping(uint32 => MarketInfo), mapping(address => fraction)) {
        return(marketInfo, tokenPrices);
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

    function updateCache(address tonWallet, mapping (uint32 => MarketInfo) _marketInfo, mapping (address => fraction) _tokenPrices) external override onlyMarket {
        marketInfo = _marketInfo;
        tokenPrices = _tokenPrices;
        tonWallet.transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    function performAction(uint32 marketId, TvmCell args, mapping (uint32 => MarketInfo) _marketInfo, mapping (address => fraction) _tokenPrices) external override onlyMarket {
        tvm.rawReserve(msg.value, 2);
        marketInfo = _marketInfo;
        tokenPrices = _tokenPrices;
        TvmSlice ts = args.toSlice();
        (address tonWallet, address userTip3Wallet, uint256 tokensToBorrow) = ts.decode(address, address, uint256);
        mapping(uint32 => fraction) updatedIndexes = _createUpdatedIndexes();
        IUAMUserAccount(userAccountManager).updateUserIndexes{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, userTip3Wallet, tokensToBorrow, marketId, updatedIndexes);
    }

    function _createUpdatedIndexes() internal view returns(mapping(uint32 => fraction) updatedIndexes) {
        for ((uint32 marketId, MarketInfo mi): marketInfo) {
            updatedIndexes[marketId] = mi.index;
        }
    }

    function borrowTokensFromMarket(
        address tonWallet,
        address userTip3Wallet,
        uint256 tokensToBorrow,
        uint32 marketId,
        mapping (uint32 => uint256) si,
        mapping (uint32 => uint256) bi
    ) external override onlyUserAccountManager {
        tvm.rawReserve(msg.value, 0);
        MarketDelta marketDelta;
        if (tokensToBorrow < marketInfo[marketId].realTokenBalance) {
            (uint256 supplySum, uint256 borrowSum) = Utilities.calculateSupplyBorrow(si, bi, marketInfo, tokenPrices);
            if (borrowSum < supplySum) {
                uint256 tmp_ = supplySum - borrowSum;
                fraction tmp = tmp_.numFDiv(tokenPrices[marketInfo[marketId].token]);
                tmp_ = tmp.toNum();
                if (tmp_ > tokensToBorrow) {
                    marketDelta.totalBorrowed.delta = tokensToBorrow;
                    marketDelta.totalBorrowed.positive = true;
                    marketDelta.realTokenBalance.delta = tokensToBorrow;
                    marketDelta.realTokenBalance.positive = false;

                    TvmBuilder tb;
                    tb.store(tonWallet);
                    tb.store(userTip3Wallet);
                    tb.store(tokensToBorrow);

                    emit TokenBorrow(marketId, marketDelta, tonWallet, tokensToBorrow);

                    IContractStateCacheRoot(marketAddress).receiveCacheDelta{
                        flag: MsgFlag.REMAINING_GAS
                    }(marketId, marketDelta, tb.toCell());
                } else {
                    IUAMUserAccount(userAccountManager).writeBorrowInformation{
                        flag: MsgFlag.REMAINING_GAS
                    }(tonWallet, userTip3Wallet, 0, marketId, marketInfo[marketId].index);
                }
            } else {
                IUAMUserAccount(userAccountManager).requestUserAccountHealthCalculation{
                    flag: MsgFlag.REMAINING_GAS
                }(tonWallet);
            }
        } else {
            address(tonWallet).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
        }
    }

    function resumeOperation(uint32 marketId, TvmCell args, mapping(uint32 => MarketInfo) _marketInfo, mapping (address => fraction) _tokenPrices) onlyMarket {
        tvm.rawReserve(msg.value, 2);
        marketInfo = _marketInfo;
        tokenPrices = _tokenPrices;
        TvmSlice ts = args.toSlice();
        (address tonWallet, address userTip3Wallet, uint256 tokensToBorrow) = ts.decode(address, address, uint256);
        IUAMUserAccount(userAccountManager).writeBorrowInformation{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, userTip3Wallet, tokensToBorrow, marketId, marketInfo[marketId].index);
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