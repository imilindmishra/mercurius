// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MercuriusFactory} from "../src/MercuriusFactory.sol";
import {MercuriusPool} from "../src/MercuriusPool.sol";
import {TickMath} from "../src/libraries/TickMath.sol";

contract MercuriusFactoryTest is Test {
    MercuriusFactory public factory;

    address internal constant TOKEN_A = address(0x1);
    address internal constant TOKEN_B = address(0x2);
    uint24 internal constant FEE = 3000;
    uint160 internal constant INITIAL_PRICE = 79228162514264337593543950336;

    function setUp() public {
        factory = new MercuriusFactory();
    }

    function test_CreatePool() public {
        address poolAddress = factory.createPool(TOKEN_A, TOKEN_B, FEE, INITIAL_PRICE);
        assertNotEq(poolAddress, address(0));

        address storedAddress = factory.getPool(TOKEN_A, TOKEN_B, FEE);
        assertEq(poolAddress, storedAddress);

        MercuriusPool pool = MercuriusPool(poolAddress);
        assertEq(pool.sqrtPriceX96(), INITIAL_PRICE);

        // NEW: Check if the tick was set correctly
        int24 expectedTick = TickMath.getTickAtSqrtRatio(INITIAL_PRICE);
        assertEq(pool.tick(), expectedTick);
    }

    function test_FailCreatePoolWithIdenticalAddresses() public {
        vm.expectRevert("IDENTICAL_ADDRESSES");
        factory.createPool(TOKEN_A, TOKEN_A, FEE, INITIAL_PRICE);
    }
}