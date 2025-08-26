// test/MercuriusFactory.t.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MercuriusFactory} from "../src/MercuriusFactory.sol";
import {MercuriusPool} from "../src/MercuriusPool.sol";
import {TickMath} from "../src/libraries/TickMath.sol";

contract MercuriusFactoryTest is Test {
    MercuriusFactory factory;
    address constant TOKEN_A = 0x1111111111111111111111111111111111111111;
    address constant TOKEN_B = 0x2222222222222222222222222222222222222222;
    uint24 constant FEE = 3000;
    int24 constant START_TICK = 85176;

    function setUp() public {
        factory = new MercuriusFactory();
    }

    function testCreatePool() public {
        address poolAddress = factory.createPool(TOKEN_A, TOKEN_B, FEE, START_TICK);
        assertTrue(poolAddress != address(0));

        MercuriusPool pool = MercuriusPool(poolAddress);

        (uint160 sqrtPriceX96, ) = pool.slot0();
        uint160 expectedSqrtPrice = TickMath.getSqrtRatioAtTick(START_TICK);
        
        assertEq(sqrtPriceX96, expectedSqrtPrice);
        assertEq(address(pool.factory()), address(factory));
    }
}