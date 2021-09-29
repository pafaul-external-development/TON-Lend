pragma ton-solidity >= 0.43.0;

import '../MarketInfo.sol';

import "../libraries/CostConstants.sol";
import "../libraries/MarketErrorCodes.sol";
import "../libraries/MarketOperations.sol";

import "../../Controllers/interfaces/ICCMarketDeployed.sol";
import "../../TIP3Deployer/interfaces/ITIP3Deployer.sol";
import "../../WalletController/interfaces/IWalletControllerMarketInteractions.sol";
import "../../ModulesForMarket/interfaces/IModule.sol";
import "../../UserAccount/interfaces/IUserAccount.sol";
import "../../UserAccount/interfaces/IUAMUserAccount.sol";
import "../../Oracle/interfaces/IOracleReturnPrices.sol";

import "../../utils/TIP3/interfaces/IRootTokenContract.sol";
import "../../utils/interfaces/IUpgradableContract.sol";
import "../../utils/libraries/MsgFlag.sol";
import "../../utils/libraries/FloatingPointOperations.sol";

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
    function mintVTokens(address tonWallet, address userTip3Wallet, uint32 marketId, uint256 toMint) external view;
    function requestTokenPayout(address tonWallet, address userTip3Wallet, uint32 marketId, uint256 toPayout) external view;
    function transferVTokensBack(address tonWallet, address userTip3Wallet, uint32 marketId, uint256 tokensToReturn) external view;
}