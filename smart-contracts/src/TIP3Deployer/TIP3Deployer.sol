pragma ton-solidity >= 0.39.0;
pragma AbiHeader pubkey;
pragma AbiHeader expire;
pragma AbiHeader time;

import './interfaces/ITIP3Deployer.sol';
import './interfaces/ITIP3DeployerManageCode.sol';
import './interfaces/ITIP3DeployerServiceInfo.sol';

import '../utils/TIP3/RootTokenContract.sol';

// import "../../utils/interfaces/IRootTokenContract.sol";

contract TIP3TokenDeployer is ITIP3Deployer, ITIP3DeployerManageCode, ITIP3DeployerServiceInfo {
    TvmCell rootContractCode;
    TvmCell walletContractCode;
    address ownerAddress;

    constructor(address ownerAddress_) public {
        tvm.accept();
        ownerAddress = ownerAddress_;
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