pragma ton-solidity >= 0.39.0;

struct IRootTokenContractDetails {
    bytes name;
    bytes symbol;
    uint8 decimals;
    uint256 root_public_key;
    address root_owner_address;
    uint128 total_supply;
}

interface ITIP3Deployer {
    function deployTIP3(IRootTokenContractDetails rootInfo, uint128 deployGrams, uint256 pubkeyToInsert) external responsible returns(address);

    function getFutureTIP3Address(IRootTokenContractDetails rootInfo, uint256 pubkeyToInsert) external responsible returns(address);
}