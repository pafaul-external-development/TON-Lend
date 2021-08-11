pragma ton-solidity >= 0.39.0;
pragma AbiHeader pubkey;
pragma AbiHeader expire;
pragma AbiHeader time;

import "./interfaces/IUserAccountManager.sol";

import "./libraries/UserAccountErrorCodes.sol";

import "../Controllers/interfaces/IReceiveAddressCallback.sol";
import "../Controllers/interfaces/ICCCodeManager.sol";
import "../Controllers/libraries/PlatformCodes.sol";

import "../utils/interfaces/IUpgradableContract.sol";
import "../utils/libraries/MsgFlag.sol";
import "../utils/Platform/Platform.sol";

contract UserAccountManager is IUpgradableContract, IReceiveAddressCallback {
    // Information for update
    address root;
    uint8 contractType;
    uint32 contractCodeVersion;
    TvmCell platformCode;

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
            address gasTo ?
        refs:
            1. platformCode
     */
    function onCodeUpgrade(TvmCell data) private {
        TvmSlice dataSlice = data.toSlice();
        (address root_, uint8 platformType, address sendGasTo) = dataSlice.decode(address, uint8, address);
        root = root_;
        contractType = platformType;

        platformCode = dataSlice.loadRef();         // Loading platform code
    }

    /*********************************************************************************************************/
    // Functions for user account
    function createUserAccount(address tonWallet) external responsible view returns (address) {
        TvmCell empty;
        IContractControllerCodeManager(root).createContract{
            value: 0,
            bounce: false,
            flag: MsgFlag.REMAINING_GAS,
            callback: this.getDeployedAddressCallback
        }(PlatformCodes.USER_ACCOUNT, _buildUserAccountInitialData(tonWallet), empty);
    }

    // TODO: return remaining gas to owner
    function getDeployedAddressCallback(address) external override onlyRoot {
        revert();
    }

    // address calculation functions
    function calculateUserAccountAddress(address tonWallet) external responsible view returns (address) {
        return { value: 0, bounce: false, flag: MsgFlag.REMAINING_GAS } address(tvm.hash(_buildUserAccountData(tonWallet)));
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
    // modifiers
    modifier onlyRoot() {
        require(msg.sender == root, UserAccountErrorCodes.ERROR_NOT_ROOT);
        _;
    }

    modifier correctContractType(uint8 contractType_) {
        require(contractType == contractType_, UserAccountErrorCodes.ERROR_INVALID_CONTRACT_TYPE);
        _;
    }
}