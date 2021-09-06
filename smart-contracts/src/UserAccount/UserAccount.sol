pragma ton-solidity >= 0.39.0;
pragma AbiHeader pubkey;
pragma AbiHeader expire;
pragma AbiHeader time;

import "./interfaces/IUserAccount.sol";
import "./interfaces/IUserAccountDataOperations.sol";
import "./libraries/UserAccountErrorCodes.sol";

import "../utils/interfaces/IUpgradableContract.sol";
import "../utils/libraries/MsgFlag.sol";

contract UserAccount is IUserAccount, IUserAccountDataOperations, IUpgradableContract {
    address msigOwner;
    // TODO: add userAccountManager
    address userAccountManager;

    // Information for update
    address root;
    uint8 contractType;
    uint32 contractCodeVersion;
    TvmCell platformCode;

    mapping(uint32 => TvmCell) userData;

    mapping(uint32 => TvmCell) markets;

    // Contract is deployed via platform
    constructor() public { 
        revert(); 
    }

    /*  Upgrade Data for version 0 (from Platform):
        bits:
            address root
            uint8 platformType
            address gasTo ?
        refs:
            1. platformCode
            2. initialData
                bits:
                    address msigOwner
     */
    function onCodeUpgrade(TvmCell data) private {
        tvm.resetStorage();
        TvmSlice dataSlice = data.toSlice();
        address sendGasTo;
        (root, contractType, sendGasTo) = dataSlice.decode(address, uint8, address);
        contractCodeVersion = 0;

        platformCode = dataSlice.loadRef();         // Loading platform code
        TvmSlice ownerData = dataSlice.loadRefAsSlice();
        (msigOwner) = ownerData.decode(address);

        address(msigOwner).transfer({ value: 0, bounce: false, flag: MsgFlag.REMAINING_GAS });
    }

    /*  Upgrade data for version 1 (from 0):
        bits:
            address root
            uint8 platformType
            uint32 contractVersion
        refs:
            1. TvmCell platformCode
            2. user data:
                bits:
                    address msigOwner
                refs:
                    1. mapping(address => TvmCell) userData
     */
    function upgradeContractCode(TvmCell code, TvmCell updateParams, uint32 codeVersion_, uint8 contractType_) override external onlyRoot correctContractType(contractType_) {
        contractCodeVersion = codeVersion_;

        TvmBuilder builder;
        builder.store(root);
        builder.store(contractType);
        builder.store(codeVersion_);
        builder.store(platformCode);

        TvmBuilder userDataBuilder;
        userDataBuilder.store(msigOwner);
        TvmBuilder userDataMapping;
        userDataMapping.store(userData);
        userDataBuilder.store(userDataMapping.toCell());
        builder.store(userDataBuilder.toCell());

        tvm.setcode(code);
        tvm.setCurrentCode(code);

        onCodeUpgrade(builder.toCell());
    }

    function getOwner() external override responsible view returns(address) {
        return { value: 0, bounce: false, flag: MsgFlag.REMAINING_GAS } msigOwner;
    }



    /*********************************************************************************************************/
    // Market callbacks functions
    function fetchInformation(TvmCell payload) external override responsible returns(address, TvmCell) {
        tvm.rawReserve(msg.value, 2);
        TvmCell information;
        // TODO: get information
        return {flag: MsgFlag.REMAINING_GAS} (msigOwner, information);
    }    

    /*********************************************************************************************************/

    // Functon can only be called by the AccauntManaget contract
    function enterMarket(uint32 marketId) external override onlyRoot {
        tvm.rawReserve(msg.value, 2);
        // TODO: enter market
        address(msigOwner).transfer({value: 0, flag: MsgFlag.REMAINING_GAS});
    }

    // function getAllData(TvmCell request) external override responsible view returns (TvmCell, bool) {

    // }

    // function getProvideData(TvmCell request) external override responsible view returns (TvmCell, bool) {

    // }

    // function getBorrowData(TvmCell request) external override responsible view returns (TvmCell, bool) {

    // }

    // function getRepayData(TvmCell request) external override responsible view returns (TvmCell, bool) {

    // }

    // function getLiquidationData(TvmCell request) external override responsible view returns (TvmCell, bool) {

    // }

    // function writeProvideData(TvmCell data) external override responsible returns (TvmCell, bool) {

    // }

    // function writeBorrowData(TvmCell data) external override responsible returns (TvmCell, bool) {

    // }

    // function writeRepayData(TvmCell data) external override responsible returns (TvmCell, bool) {

    // }

    // function writeLiquidationData(TvmCell data) external override responsible returns (TvmCell, bool) {

    // }



    /*********************************************************************************************************/
    // modifiers
    modifier onlyRoot() {
        require(msg.sender == root);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == msigOwner);
        _;
    }

    modifier onlyUserAccountManager() {
        require(msg.sender == userAccountManager);
        _;
    }

    modifier correctContractType(uint8 contractType_) {
        require(contractType == contractType_);
        _;
    }
}