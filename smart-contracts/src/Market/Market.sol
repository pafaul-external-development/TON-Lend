pragma ton-solidity >= 0.39.0;

import "../utils/interfaces/IUpgradableContract.sol";
import "./interfaces/IBorrow.sol";
import "./interfaces/ISupply.sol";
import "./interfaces/IRepay.sol";
import "./interfaces/ILiquidate.sol";


contract Market is IUpgradableContract, IBorrow, ISupply, IRepay, ILiquidate {
    address token;
    address wrappedToken;

    address walletController;
    address oracle;
    address contractController;

    uint32 kinkNominator;
    uint32 kinkDenominator;
    uint32 collateralFactorNominator;
    uint32 collateralFactorDenominator;


    uint32 contractCodeVersion;
    TvmCell platformCode;


    constructor() public {
        revert();
    }

    // TODO
    function onCodeUpgrade(TvmCell data) private {

    }

    // TODO: доделать
    function upgradeContractCode(TvmCell code, TvmCell updateParams, uint32 codeVersion_, uint8 contractType_) 
        override 
        external 
        onlyRoot 
        correctContractType(contractType_) 
    { 
        contractCodeVersion = condeVersion_;

        TvmBuilder builder;
        // builder.store(root);
        // builder.store(contractType);
        // builder.store(platformCode);

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
}