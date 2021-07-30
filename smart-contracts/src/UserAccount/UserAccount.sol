pragma ton-solidity >= 0.39.0;
pragma AbiHeader pubkey;
pragma AbiHeader expire;
pragma AbiHeader time;

import "./interfaces/IUserAccount.sol";
import "./interfaces/IUserAccountDataOperations.sol";

import "../utils/interfaces/IUpgradableContract.sol";

contract UserAccount is IUserAccount, IUserAccountDataOperations, IUpgradableContract {
    address msigOwner;

    // Information for update
    address root;
    uint8 contractType;
    uint32 contractCodeVersion;
    TvmCell platformCode;

    // User data
    // TODO: определиться с хранимыми данными и способом доступа к ним
    mapping(address => TvmCell) userData;

    // Contract is deployed via platform
    constructor() public { revert(); }

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
        TvmSlice dataSlice = data.toSlice();
        (address root, uint8 contractType, address sendGasTo) = dataSlice.decode(address, uint8, address);
        contractCodeVersion = 0;

        platformCode = dataSlice.loadRef();         // Loading platform code
        TvmSlice data = dataSlice.loadRefAsSlice();
        (msigOwner) = dataSlice.decode(address);
    }

    /*  Upgrade data for version 1 (from 0):
        bits:
            address root
            uint8 platformType
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
        builder.store(platformType);
        builder.store(platformCode);

        TvmBuilder userDataBuilder;
        userDataBuilder.store(msigOwner);
        TvmBuilder userDataMapping;
        userDataMapping.store(userData);
        userDataBuilder.store(userDataMapping.toCell());
        builder.store(userDataBuilder.toCell());
        onCodeUpgrade(builder.toCell());
    }

    function getOwner() external responsible view returns(address) {
        return { value: 0, bounce: false, flag: MsgFlag.REMAINING_GAS } msigOwner;
    }

    function enterMarket(address market) external responsible view returns(address) onlyOwner {

    }


    function getAllData(TvmCell request) external responsible view returns (TvmCell, bool) {

    }
    function getProvideData(TvmCell request) external responsible view returns (TvmCell, bool) {

    }
    function getBorrowData(TvmCell request) external responsible view returns (TvmCell, bool) {

    }
    function getRepayData(TvmCell request) external responsible view returns (TvmCell, bool) {

    }
    function getLiquidationData(TvmCell request) external responsible view returns (TvmCell, bool) {

    }

    function writeProvideData(TvmCell data) external responsible returns (TvmCell, bool) {

    }
    function writeBorrowData(TvmCell data) external responsible returns (TvmCell, bool) {

    }
    function writeRepayData(TvmCell data) external responsible returns (TvmCell, bool) {

    }
    function writeLiquidationData(TvmCell data) external responsible returns (TvmCell, bool) {

    }

    // modifiers
    modifier onlyOwner() {
        require(msg.sender == msigOwner);
        _;
    }

    modifier correctContractType(uint8 contractType_) {
        require(contractType == contractType_);
        _;
    }
}