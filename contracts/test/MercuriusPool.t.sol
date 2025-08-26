// test/MercuriusPool.t.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MercuriusFactory} from "../src/MercuriusFactory.sol";
import {MercuriusPool} from "../src/MercuriusPool.sol";
import {TickMath} from "../src/libraries/TickMath.sol";

contract MercuriusPoolTest is Test {
    MercuriusFactory factory;
    MercuriusPool pool;

    address constant TOKEN_A = 0x1111111111111111111111111111111111111111;
    address constant TOKEN_B = 0x2222222222222222222222222222222222222222;
    uint24 constant FEE = 3000;
    int24 constant START_TICK = 85176;

    function setUp() public {
        // 1. Deploy the factory
        factory = new MercuriusFactory();
        
        // 2. Use the factory to create the pool
        address poolAddress = factory.createPool(TOKEN_A, TOKEN_B, FEE, START_TICK);
        
        // 3. Store the pool instance for our tests
        pool = MercuriusPool(poolAddress);
    }

    function testInitialState() public {
        // Check that the pool was created with the correct initial state
        (uint160 sqrtPriceX96, int24 tick) = pool.slot0();
        
        uint160 expectedSqrtPrice = TickMath.getSqrtRatioAtTick(START_TICK);

        assertEq(sqrtPriceX96, expectedSqrtPrice, "Initial price is incorrect");
        assertEq(tick, START_TICK, "Initial tick is incorrect");
        assertEq(pool.liquidity(), 0, "Initial liquidity should be 0");
    }

    
}