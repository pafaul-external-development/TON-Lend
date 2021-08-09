pragma ton-solidity >= 0.39.0;

import "../../utils/interfaces/IRootTokenContract.sol";

interface ITIP3Deployer {
    function deployTIP3(IRootTokenContractDetails rootInfo, uint128 deployGrams) external responsible returns(address);
}