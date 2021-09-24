pragma ton-solidity >= 0.43.0;

import "../../UserAccount/interfaces/IUserAccount.sol";
import "../../UserAccount/interfaces/IUAMUserAccount.sol";
import "../../Oracle/interfaces/IOracleReturnPrices.sol";
import "../../utils/TIP3/interfaces/IRootTokenContract.sol";

import "../../utils/libraries/FloatingPointOperations.sol";

struct MarketInfo {
    address token;
    address virtualToken;
    uint256 currentPoolBalance;
    uint256 totalBorrowed;
    uint256 totalReserve;
    uint256 totalSupply;
    
    fraction index;
    fraction reserveFactor;
    fraction kink;
    fraction collateral;
    fraction baseRate;
    fraction mul;
    fraction jumpMul;

    uint256 lastUpdateTime;
}

interface IMarketOracle {
    function receiveUpdatedPrice(address tokenRoot, uint128 nom, uint128 denom, TvmCell payload) external;
    function receiveAllUpdatedPrices(mapping(address => MarketPriceInfo) updatedPrices, TvmCell payload) external;
    function forceUpdatePrice(address tokenRoot) external;
    function forceUpdateAllPrices() external; 
}

interface IMarketSetters {
    function setUserAccountManager(address userAccountManager_) external;
    function setTip3WalletController(address tip3WalletController_) external;
    function setOracleAddress(address oracle_) external;
}

interface IMarketGetters {
    function getServiceContractAddresses() external view responsible returns(address userAccountManager_, address tip3WalletController_, address oracle_);
    function getTokenPrices() external view responsible returns(mapping(address => fraction));
    function getMarketInformation(uint32 marketId) external view responsible returns(MarketInfo);
    function getAllMarkets() external view responsible returns(mapping(uint32 => MarketInfo));
}

interface IMarketOwnerFunctions {
    function transferOwnership(address newOwner) external;
    function withdrawExtraTons(uint128 amount) external;
}

interface IMarketTIP3Root {
    function fetchTIP3Information(address realToken) external pure;
    function receiveTIP3Information(IRootTokenContract.IRootTokenContractDetails rootTokenDetails) external view;
    function receiveNewTIP3Address(address tip3RootAddress, TvmCell payload) external;
}

interface IMarketOperations {
    function supplyTokensToMarket(address tokenRoot, address tonWallet, address userTip3Wallet, uint128 tokenAmount) external;
    function mintVTokens(address tonWallet, address userTip3Wallet, uint32 marketId, uint256 toMint) external view;
    function repayBorrow(address tokenRoot, address tonWallet, address userTip3Wallet, uint128 tokenAmount, uint8 loanId) external view;
    function receiveRepayInformation(address tonWallet, address userTip3Wallet, uint32 marketId_, uint8 loanId, uint256 tokensForRepay, BorrowInfo bi) external;
    function requestTokenPayout(address tonWallet, address userTip3Wallet, uint32 marketId, uint256 toPayout) external view;
    function receiveBorrowInformation(address tonWallet, uint32 marketId_, address userTip3Wallet, uint256 toBorrow, mapping(uint32 => uint256) bi, mapping(uint32 => uint256) si) external;
    function requestIndexUpdate(address tonWallet, uint32 marketId, mapping (uint32=>bool) upd, address tip3UserWallet, uint256 amountToBorrow) external view;
    function withdrawVToken(address tokenRoot, address tonWallet, address userTip3Wallet, address originalTip3Wallet, uint128 tokenAmount) external;
    function receiveWithdrawInfo(
        address tonWallet, 
        address userTip3Wallet, 
        address originalTip3Wallet, 
        uint32 marketId, 
        uint256 tokensToWithdraw, 
        mapping(uint32 => uint256) bi, 
        mapping(uint32 => uint256) si
    ) external;
    function transferVTokensBack(address tonWallet, address userTip3Wallet, uint32 marketId, uint256 tokensToReturn) external view;
}