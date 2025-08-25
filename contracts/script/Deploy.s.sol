// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {MercuriusFactory} from "../src/MercuriusFactory.sol";
import {Router} from "../src/Router.sol";
import {NonfungiblePositionManager} from "../src/NonfungiblePositionManager.sol";
import {TickMath} from "../src/libraries/TickMath.sol";

contract Deploy is Script {
    // Sepolia Testnet Addresses
    address constant WETH = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;
    address constant USDC = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7a90;

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

        // 1. Deploy the Factory
        MercuriusFactory factory = new MercuriusFactory();
        factoryAddr = address(factory);

        // 2. Deploy the Router
        Router router = new Router(factoryAddr);
        routerAddr = address(router);

        // 3. Deploy the NonfungiblePositionManager
        NonfungiblePositionManager positionManager = new NonfungiblePositionManager(
            factoryAddr
        );
        positionManagerAddr = address(positionManager);

        // 4. Create the first pool (WETH/USDC)
        // We'll set the initial price to be ~1 WETH = 3000 USDC
        // This corresponds to a specific tick.
        int24 startTick = 207218; // Corresponds to sqrtPriceX96 for 3000 USDC/WETH
        
        poolAddr = factory.createPool(
            WETH,
            USDC,
            3000, // 0.3% fee tier
            startTick
        );

        vm.stopBroadcast();
    }
}