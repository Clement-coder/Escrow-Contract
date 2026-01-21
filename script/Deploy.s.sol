// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {EscrowContract} from "../src/EscrowContract.sol";

contract DeployEscrowContract is Script {
    function run() external returns (EscrowContract) {
        vm.startBroadcast();
        
        EscrowContract escrow = new EscrowContract();
        console.log("EscrowContract deployed to:", address(escrow));
        
        vm.stopBroadcast();
        return escrow;
    }
}
