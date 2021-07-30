pragma ton-solidity >= 0.39.0;
pragma AbiHeader pubkey;
pragma AbiHeader expire;
pragma AbiHeader time;

import "./interfaces/ITIP3ControllerMarketInteractions.sol";
import "../utils/interfaces/IUpgradableContract.sol";

contract TIP3Controller is ITIP3ControllerMarketInteractions, IUpgradableContract {

}