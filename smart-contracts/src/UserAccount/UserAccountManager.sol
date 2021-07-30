pragma ton-solidity >= 0.39.0;
pragma AbiHeader pubkey;
pragma AbiHeader expire;
pragma AbiHeader time;

import "./interfaces/IUserAccountManager.sol";

import "../utils/interfaces/IUpgradableContract.sol";

contract UserAccountManager {
    // Information for update
    address root;
    uint8 contractType;
    uint32 contractCodeVersion;
    TvmCell platformCode;

    // Contract is deployed via platform
    constructor() public { revert(); }

    /*  Upgrade Data for version 1 (from version 0):
        bits:
            address root
            uint8 contractType
        refs:
            1. platformCode
     */
    function upgradeContractCode(TvmCell code, TvmCell updateParams, uint32 codeVersion_, uint8 contractType_) override external onlyRoot correctContractType(contractType_) {
        tvm.accept();

        contractCodeVersion = codeVersion_;

        TvmBuilder builder;
        builder.store(root);
        builder.store(contractType);
        builder.store(platformCode);

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

    function createUserAccount(address tonWallet) external responsible view returns (address) {

    }

    function calculateUserAccountAddress(address tonWallet) external responsible view returns (address) {
        
    }

    // modifiers
    modifier correctContractType(uint8 contractType_) {
        require(contractType == contractType_);
        _;
    }
}