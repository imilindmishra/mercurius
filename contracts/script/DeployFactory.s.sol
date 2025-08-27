// contracts/script/DeployFactory.s.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {MercuriusFactory} from "../src/MercuriusFactory.sol";

contract DeployFactory is Script {
    function run() external returns (address factoryAddr) {
        vm.startBroadcast();

        MercuriusFactory factory = new MercuriusFactory();
        factoryAddr = address(factory);

        vm.stopBroadcast();
    }
}