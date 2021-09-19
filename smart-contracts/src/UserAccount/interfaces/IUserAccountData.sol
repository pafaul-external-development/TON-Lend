pragma ton-solidity >= 0.39.0;

interface IUserAccountData {
        function updateIndexes(uint32 marketId_, mapping(uint32 => fraction) newIndexes, address userTip3Wallet, uint256 toBorrow) external;
        
}