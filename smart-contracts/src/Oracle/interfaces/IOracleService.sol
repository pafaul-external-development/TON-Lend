pragma ton-solidity >= 0.39.0;
pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

interface IOracleService {
    struct OracleServiceInformation {
        uint32 codeVersion;
        address ownerAddress;
        uint256 ownerPubkey;
    }
    
    function getVersion() external responsible view returns (uint32);
    function getDetails() external responsible view returns (OracleServiceInformation);

    function changeOwnerPubkey(uint256 newOwnerPubkey) external;
    function changeOwnerAddress(address newOwnerAddress) external;
}