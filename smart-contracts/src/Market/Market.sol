pragma ton-solidity >= 0.39.0;

import "./libraries/CostConstants.sol";
import "./libraries/MarketErrorCodes.sol";

import "../Controllers/interfaces/ICCMarketDeployed.sol";
import "../TIP3Deployer/interfaces/ITIP3Deployer.sol";

import "../utils/interfaces/IUpgradableContract.sol";
import "../utils/TIP3/interfaces/IRootTokenContract.sol";

// import "./interfaces/IBorrow.sol";
// import "./interfaces/ISupply.sol";
// import "./interfaces/IRepay.sol";
// import "./interfaces/ILiquidate.sol";

contract Market is IUpgradableContract 
// , IBorrow, ISupply, IRepay, ILiquidate
{
    // Information for update
    address root;
    uint8 contractType;
    uint32 contractCodeVersion;
    TvmCell platformCode;

    // External contracts
    address token;
    address wrappedToken;

    // Contract addresses
    address tip3Deployer;
    address walletController;
    address oracle;

    // Market parameters
    uint32 kinkNominator;
    uint32 kinkDenominator;
    uint32 collateralFactorNominator;
    uint32 collateralFactorDenominator;

    /*********************************************************************************************************/
    // Base functions - for deploying and upgrading contract
    // We are using Platform so constructor is not available
    constructor() public {
        revert();
    }

    /**
     * @param code New contract code
     * @param updateParams Extrenal parameters used during update
     * @param codeVersion_ New code version
     * @param contractType_ Contract type of received update
     */
    function upgradeContractCode(TvmCell code, TvmCell updateParams, uint32 codeVersion_, uint8 contractType_) override external onlyRoot correctContractType(contractType_) {
        tvm.accept();

        TvmBuilder builder;

        tvm.setcode(code);
        tvm.setCurrentCode(code);

        onCodeUpgrade(builder.toCell());
    }
    
    /*
        Data for upgrade from platform to version 0:
        data:
            bits:
                address root
                uint8 contractType
            refs:
                1. platformCode
                2. initialData
                    bits:
                        1. address token
                    refs:
                        1. Custom contracts
                            bits:
                                1. address TIP3Deployer
                                2. address WalletController
                                3. address Oracle
    */
    /**
     * @param data Data builded in upgradeContractCode
     */
    function onCodeUpgrade(TvmCell data) private {
        tvm.resetStorage();
        TvmSlice dataSlice = data.toSlice();
        (root, contractType) = dataSlice.decode(address, uint8);
        contractCodeVersion = 0;

        platformCode = dataSlice.loadRef();         // Loading platform code
        TvmSlice initialParametersRef = dataSlice.loadRefAsSlice();  // Loading initial parameters
        (token) = initialParametersRef.decode(address); // decode bits of initial parameters
        TvmSlice contractAddresses = initialParametersRef.loadRefAsSlice(); // load information about contracts
        (tip3Deployer, walletController, oracle) = contractAddresses.decode(address, address, address);
        
        this.fetchTIP3Information();
    }

    /*********************************************************************************************************/
    // functions for interfaction with TIP-3 tokens
    function fetchTIP3Information() external view onlySelf {
        IRootTokenContract(token).getDetails{
            value: CostConstants.FETCH_TIP3_ROOT_INFORMATION,
            bounce: true,
            callback: this.receiveTIP3Information
        }();
    }

    /**
     * @param rootTokenDetails Received information about real token
     */
    function receiveTIP3Information(IRootTokenContract.IRootTokenContractDetails rootTokenDetails) external view onlyRealTokenRoot {
        tvm.accept();
        prepareDataForNewTIP3(rootTokenDetails);
    }

    /**
     * @param rootTokenDetails Received information about real token
     */
    function prepareDataForNewTIP3(IRootTokenContract.IRootTokenContractDetails rootTokenDetails) private view {
        IRootTokenContract.IRootTokenContractDetails newRootInfo;
        string initialName = "v";
        initialName.append(string(rootTokenDetails.name));
        newRootInfo.name = bytes(initialName);
        string initialSymbol = "v";
        initialSymbol.append(string(rootTokenDetails.symbol));
        newRootInfo.symbol = bytes(initialSymbol);
        newRootInfo.decimals = rootTokenDetails.decimals;
        newRootInfo.root_public_key = 0;
        newRootInfo.root_owner_address = address(this);
        newRootInfo.total_supply = 0;
        deployNewTIP3Token(newRootInfo);
    }

    /**
     * @param newRootTokenDetails Root token information prepared for new token deployment
     */
    function deployNewTIP3Token(IRootTokenContract.IRootTokenContractDetails newRootTokenDetails) private view {
        tvm.accept();
        ITIP3Deployer(tip3Deployer).deployTIP3{
            value: CostConstants.SEND_TO_TIP3_DEPLOYER,
            bounce: false,
            callback: this.receiveNewTIP3Address
        }(newRootTokenDetails, CostConstants.USE_TO_DEPLOY_TIP3_ROOT, tvm.pubkey());
    }

    /**
     * @param tip3RootAddress Received address of virtual token root
     */
    function receiveNewTIP3Address(address tip3RootAddress) external onlyTIP3Deployer {
        tvm.accept();
        wrappedToken = tip3RootAddress;
        ICCMarketDeployed(root).marketDeployed{
            value: CostConstants.NOTIFY_CONTRACT_CONTROLLER,
            bounce: false
        }(token, wrappedToken);
    }

    /*********************************************************************************************************/
    // modifiers

    modifier onlyRoot() {
        require(msg.sender == root, MarketErrorCodes.ERROR_MSG_SENDER_IS_NOT_ROOT);
        _;
    }

    modifier onlySelf() {
        require(msg.sender == address(this), MarketErrorCodes.ERROR_MSG_SENDER_IS_NOT_SELF);
        _;
    }

    modifier onlyRealTokenRoot() {
        require(msg.sender == token, MarketErrorCodes.ERROR_MSG_SENDER_IS_NOT_REAL_TOKEN);
        _;
    }

    modifier onlyVirtualTokenRoot() {
        require(msg.sender == wrappedToken, MarketErrorCodes.ERROR_MSG_SENDER_IS_NOT_VIRTUAL_TOKEN);
        _;
    }

    modifier onlyTIP3Deployer() {
        require(msg.sender == tip3Deployer, MarketErrorCodes.ERROR_MSG_SENDER_IS_NOT_TIP3_DEPLOYER);
        _;
    }

    /**
     * @param contractType_ Type of contract
     */
    modifier correctContractType(uint8 contractType_) {
        require(contractType == contractType_, MarketErrorCodes.ERROR_INVALID_CONTRACT_TYPE);
        _;
    }
}
