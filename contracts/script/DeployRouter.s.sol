// contracts/script/DeployRouter.s.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Router} from "../src/Router.sol";

contract DeployRouter is Script {
    // The official WETH address on Arbitrum Sepolia
    address constant WETH9 = 0x980B62da8771239048306449620448950005f15A;

    function run(address factoryAddress)
        external
        returns (address routerAddr)
    {
        vm.startBroadcast();

        // Deploy the Router, passing in the EXISTING factory address and the correct WETH9 address
        Router router = new Router(factoryAddress, WETH9);
        routerAddr = address(router);

        console.log("New Router deployed at:", routerAddr);
        console.log("Connected to Factory at:", factoryAddress);

        vm.stopBroadcast();
    }
}