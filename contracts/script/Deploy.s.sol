// script/Deploy.s.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {MercuriusFactory} from "../src/MercuriusFactory.sol";
import {Router} from "../src/Router.sol";
import {NonfungiblePositionManager} from "../src/NonfungiblePositionManager.sol";

contract Deploy is Script {
    // Optimism Sepolia Testnet Addresses
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant USDC = 0x7E07E15D2a87A24492740D16f5bdF58c16db0c4E;

    function run()
        external
        returns (
            address factoryAddr,
            address routerAddr,
            address positionManagerAddr,
            address poolAddr
        )
    {
        vm.startBroadcast();

        MercuriusFactory factory = new MercuriusFactory();
        factoryAddr = address(factory);

        Router router = new Router(factoryAddr, WETH);
        routerAddr = address(router);

        NonfungiblePositionManager positionManager = new NonfungiblePositionManager(
            factoryAddr
        );
        positionManagerAddr = address(positionManager);
        
        // We will create a WETH/USDC pool.
        int24 startTick = 207218; 
        
        poolAddr = factory.createPool(
            WETH,
            USDC,
            3000,
            startTick
        );

        vm.stopBroadcast();
    }
}