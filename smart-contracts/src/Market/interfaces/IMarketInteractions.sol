pragma ton-solidity >= 0.43.0;

import "../../UserAccount/interfaces/IUAMUserAccount.sol";
import "../../Oracle/interfaces/IOracleReturnPrices.sol";
import "../../utils/TIP3/interfaces/IRootTokenContract.sol";

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

interface IMarketOwnerFunctions {
    function transferOwnership(address newOwner) external;
    function withdrawExtraTons(uint128 amount) external;
}

interface IMarketTIP3Root {
    function fetchTIP3Information(address realToken) external pure;
    function receiveTIP3Information(IRootTokenContract.IRootTokenContractDetails rootTokenDetails) external view;
    function receiveNewTIP3Address(address tip3RootAddress, TvmCell payload) external;
}