pragma ton-solidity ^0.39.0;

import "../libraries/MsgFlag.sol";


contract Platform {
    address static root;
    uint8 static platformType;
    TvmCell static initialData;
    TvmCell static platformCode;

    constructor(TvmCell code, TvmCell params, address sendGasTo) public {
        if (msg.sender != root) {
           msg.sender.transfer({value: 0, flag: MsgFlag.ALL_NOT_RESERVED + MsgFlag.DESTROY_IF_ZERO, bounce: false});
        } else {
            initialize(code, params, sendGasTo);
        }
    }

    function initialize(TvmCell params, address sendGasTo) private {

        TvmBuilder builder;

        builder.store(root);
        builder.store(platformType);
        builder.store(sendGasTo);

        builder.store(initialData);  // ref 1
        builder.store(params);       // ref 2

        tvm.setcode(platformCode);
        tvm.setCurrentCode(platformCode);

        onCodeUpgrade(builder.toCell());
    }

    function onCodeUpgrade(TvmCell data) private {}
}