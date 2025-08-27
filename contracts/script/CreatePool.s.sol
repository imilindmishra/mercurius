// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {IMercuriusFactory} from "../src/interfaces/IMercuriusFactory.sol";

contract CreatePool is Script {
    function run() external {
        // For parameter-based approach, hardcode the factory address
        address factoryAddr = 0x7c8dA50Ec2B98EcD536BfdF2C33D09302455dc2e;
        
        vm.startBroadcast();
        
        IMercuriusFactory factory = IMercuriusFactory(factoryAddr);
        address tokenA = 0x3C8Dd7870E9a8e7e996543C4ADeB643438D4Aba8;  // KAJU
        address tokenB = 0xE6DC9225E4C76f9c0b002Ab2782F687e35cc7666;  // BRFI
        address pool = factory.createPool(tokenA, tokenB, 3000, 0);  // Fee 3000, initialTick 0
        
        console.log("Pool created at:", pool);
        
        vm.stopBroadcast();
    }
}