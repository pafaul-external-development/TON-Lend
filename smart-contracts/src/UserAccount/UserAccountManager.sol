pragma ton-solidity >= 0.39.0;
pragma AbiHeader pubkey;
pragma AbiHeader expire;
pragma AbiHeader time;

import "./interfaces/IUserAccountManager.sol";
import "./interfaces/IUAMUserAccount.sol";
import "./interfaces/IUAMMarket.sol";

import "./interfaces/IUserAccount.sol";
import "./interfaces/IUserAccountData.sol";

import "./libraries/UserAccountErrorCodes.sol";

import "../Market/interfaces/IMarketCallbacks.sol";

import "../Controllers/interfaces/ICCCodeManager.sol";
import "../Controllers/libraries/PlatformCodes.sol";

import "../utils/interfaces/IUpgradableContract.sol";
import "../utils/libraries/MsgFlag.sol";
import "../utils/Platform/Platform.sol";

contract UserAccountManager is IUpgradableContract, IUserAccountManager, IUAMUserAccount, IUAMMarket {
    // Information for update
    address root;
    uint8 contractType;
    uint32 contractCodeVersion;
    TvmCell platformCode;

    address market;
    mapping(uint32 => bool) marketIds;

    /*********************************************************************************************************/
    // Functions for deployment and upgrade
    // Contract is deployed via platform
    constructor() public { revert(); }

    /*  Upgrade Data for version 1 (from version 0):
        bits:
            address root
            uint8 contractType
            uint32 codeVersion
        refs:
            1. platformCode
     */
    function upgradeContractCode(TvmCell code, TvmCell updateParams, uint32 codeVersion_, uint8 contractType_) override external onlyRoot correctContractType(contractType_) {
        tvm.accept();

        contractCodeVersion = codeVersion_;

        TvmBuilder builder;
        builder.store(root);
        builder.store(contractType);
        builder.store(codeVersion_);
        builder.store(platformCode);

        tvm.setcode(code);
        tvm.setCurrentCode(code);

        onCodeUpgrade(builder.toCell());
    }

    /*  Upgrade Data for version 0 (from Platform):
        bits:
            address root
            uint8 platformType
        refs:
            1. platformCode
     */
    function onCodeUpgrade(TvmCell data) private {
        tvm.resetStorage();
        TvmSlice dataSlice = data.toSlice();
        (root, contractType) = dataSlice.decode(address, uint8);

        platformCode = dataSlice.loadRef();         // Loading platform code
    }

    /*********************************************************************************************************/
    // Functions for user account
    function createUserAccount(address tonWallet) external override view {
        TvmCell empty;
        IContractControllerCodeManager(root).createContract{
            value: 0,
            bounce: false,
            flag: MsgFlag.REMAINING_GAS
        }(PlatformCodes.USER_ACCOUNT, _buildUserAccountInitialData(tonWallet), empty);
    }

    // address calculation functions
    function calculateUserAccountAddress(address tonWallet) external override responsible view returns (address) {
        return { value: 0, bounce: false, flag: MsgFlag.REMAINING_GAS } _calculateUserAccountAddress(tonWallet);
    }

    function _calculateUserAccountAddress(address tonWallet) internal view returns(address) {
        return address(tvm.hash(_buildUserAccountData(tonWallet)));
    }

    function _buildUserAccountData(address tonWallet) private view returns (TvmCell data) {
        TvmCell userData = _buildUserAccountInitialData(tonWallet);
        return tvm.buildStateInit({
            contr: Platform,
            varInit: {
                root: root,
                platformType: PlatformCodes.USER_ACCOUNT,
                platformCode: platformCode,
                initialData: userData
            },
            pubkey: 0,
            code: platformCode
        });
    }

    function _buildUserAccountInitialData(address tonWallet) private pure returns (TvmCell data) {
        TvmBuilder userData;
        userData.store(tonWallet);
        return userData.toCell();
    }


    /*********************************************************************************************************/
    // Functions for user account
    function enterMarket(address tonWallet, uint32 marketId) external override view responsible returns (address) {
        tvm.rawReserve(msg.value, 2);
        if (marketIds[marketId]) {
            address userAccount = _calculateUserAccountAddress(tonWallet);
            IUserAccount(userAccount).enterMarket{flag: MsgFlag.REMAINING_GAS}(marketId);
        } else {
            address(msg.sender).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
        }
    }

    function fetchInformationFromUserAccount(address tonWallet, TvmCell payload) external override view onlyMarket {
        tvm.rawReserve(msg.value, 2);
        address userAccount = _calculateUserAccountAddress(tonWallet);
        IUserAccountData(userAccount).fetchInformationFromUserAccount{
            flag: MsgFlag.REMAINING_GAS,
            callback: this.passInformationToMarket
        }(payload);
    }

    function passInformationToMarket(address tonWallet, TvmCell payload) external override view onlyValidUserAccount(tonWallet) {
        tvm.rawReserve(msg.value, 2);
        IMarketUAMCallbacks(market).receiveInformationFromUser{
            flag: MsgFlag.REMAINING_GAS
        }(tonWallet, payload);
    }

    function writeInformationToUserAccount(address tonWallet, TvmCell payload) external override view onlyMarket {
        tvm.rawReserve(msg.value, 2);
        address userAccount = _calculateUserAccountAddress(tonWallet);
        IUserAccountData(userAccount).writeInformationToUserAccount{flag: MsgFlag.REMAINING_GAS}(payload);
    }
 
    /*********************************************************************************************************/
    // Market managing functions

    function setMarketAddress(address market_) external override onlyRoot {
        tvm.accept();
        market = market_;
    }

    function addMarket(uint32 marketId) external override onlyRoot {
        tvm.accept();
        marketIds[marketId] = true;
    }

    function removeMarket(uint32 marketId) external override onlyRoot {
        tvm.accept();
        delete marketIds[marketId];
    }


    /*********************************************************************************************************/
    // modifiers
    modifier onlyRoot() {
        require(msg.sender == root, UserAccountErrorCodes.ERROR_NOT_ROOT);
        _;
    }

    modifier onlyMarket() {
        // TODO
        require(msg.sender == market);
        _;
    }

    modifier onlyValidUserAccount(address tonWallet) {
        require(msg.sender == _calculateUserAccountAddress(tonWallet));
        _;
    }

    modifier correctContractType(uint8 contractType_) {
        require(contractType == contractType_, UserAccountErrorCodes.ERROR_INVALID_CONTRACT_TYPE);
        _;
    }
}