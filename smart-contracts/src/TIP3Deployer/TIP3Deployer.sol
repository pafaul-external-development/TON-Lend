pragma ton-solidity >= 0.39.0;
pragma AbiHeader pubkey;
pragma AbiHeader expire;
pragma AbiHeader time;

import './interfaces/ITIP3Deployer.sol';
import './interfaces/ITIP3DeployerManageCode.sol';
import './interfaces/ITIP3DeployerServiceInfo.sol';

import '../utils/interfaces/IUpgradableContract.sol';
import '../utils/TIP3/RootTokenContract.sol';

contract TIP3TokenDeployer is ITIP3Deployer, ITIP3DeployerManageCode, ITIP3DeployerServiceInfo, IUpgradableContract {
    TvmCell rootContractCode;
    TvmCell walletContractCode;
    address ownerAddress;

    // Information for update
    address root;
    uint8 contractType;
    uint32 contractCodeVersion;
    TvmCell platformCode;


    constructor() public {
        revert();
    }

    /** Upgrade contract code from version 0 to 1
      Data:
        bits:
            1. address root
            2. uint8 contractType
            3. uint32 codeVersion
        refs:
            1. TvmCell platform code
            3. ownerInfo:
                bits:
                    1. address ownerAddress
            2. codeInfo:
                refs:
                    1. TvmCell rootContractCode
                    2. TvmCell walletContractCode
     */
    function upgradeContractCode(TvmCell code, TvmCell updateParams, uint32 codeVersion_, uint8 contractType_) override external onlyRoot correctContractType(contractType_) {
        TvmBuilder builder;
        builder.store(root);
        builder.store(contractType);
        builder.store(codeVersion_);
        builder.store(platformCode);

        // Store owner info
        TvmBuilder ownerInfo;
        ownerInfo.store(ownerAddress);

        TvmBuilder codeInfo;
        codeInfo.store(rootContractCode);
        codeInfo.store(walletContractCode);

        builder.store(ownerInfo.toCell());
        builder.store(codeInfo.toCell());

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
            2. initialData:
                bits:
                    address ownerAddress
     */
    function onCodeUpgrade(TvmCell data) private {
        tvm.accept();
        TvmSlice dataSlice = data.toSlice();
        (root, contractType) = dataSlice.decode(address, uint8);

        platformCode = dataSlice.loadRef();         // Loading platform code
        TvmSlice ref = dataSlice.loadRefAsSlice();  // Loading initial parameters
        (ownerAddress) = ref.decode(address);
    }

    function deployTIP3(IRootTokenContractDetails rootInfo, uint128 deployGrams, uint256 pubkeyToInsert) external responsible override returns (address) {
        tvm.rawReserve(msg.value, 2);
        address tip3TokenAddress = new RootTokenContract{
            value: deployGrams,
            flag: 0,
            code: rootContractCode,
            pubkey: pubkeyToInsert,
            varInit: {
                _randomNonce: 0,
                name: rootInfo.name,
                symbol: rootInfo.symbol,
                decimals: rootInfo.decimals,
                wallet_code: walletContractCode 
            }
        }(rootInfo.root_public_key, rootInfo.root_owner_address);

        return {value: 0, flag: 64} tip3TokenAddress;
    }

    function getFutureTIP3Address(IRootTokenContractDetails rootInfo, uint256 pubkeyToInsert) external override responsible returns (address) {
        tvm.accept();
        TvmCell stateInit = tvm.buildStateInit({
            contr: RootTokenContract,
            code: rootContractCode,
            pubkey: pubkeyToInsert,
            varInit: {
                _randomNonce: 0,
                name: rootInfo.name,
                symbol: rootInfo.symbol,
                decimals: rootInfo.decimals,
                wallet_code: walletContractCode 
            }
        });

        return address.makeAddrStd(0, tvm.hash(stateInit));
    }

    function setTIP3RootContractCode(TvmCell rootContractCode_) external override onlyOwner {
        tvm.accept();
        rootContractCode = rootContractCode_;
    }

    function setTIP3WalletContractCode(TvmCell walletContractCode_) external override onlyOwner {
        tvm.accept();
        walletContractCode = walletContractCode_;
    }

    function getServiceInfo() external override responsible view returns (ServiceInfo) {
        return ServiceInfo(rootContractCode, walletContractCode);
    }

    modifier onlyOwner() {
        require(
            msg.sender == ownerAddress
        );
        _;
    }
}