// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MercuriusPool} from "../src/MercuriusPool.sol";
import {TickMath} from "../src/libraries/TickMath.sol";

contract MercuriusPoolTest is Test {
    MercuriusPool pool;

    address internal constant TOKEN_A = address(0x1);
    address internal constant TOKEN_B = address(0x2);
    uint24 internal constant FEE = 3000;
    uint160 internal constant INITIAL_PRICE = 79228162514264337593543950336; // 1:1 price

    function setUp() public {
        pool = new MercuriusPool(TOKEN_A, TOKEN_B, FEE, INITIAL_PRICE);

        // Add some initial liquidity to the pool for swapping
        pool.mint(address(this), TickMath.MIN_TICK, TickMath.MAX_TICK, 1e18);
    }

    function test_Mint() public {
        uint128 liquidityAmount = 100;
        int24 tickLower = -10;
        int24 tickUpper = 10;

        (uint256 amount0, uint256 amount1) = pool.mint(address(this), tickLower, tickUpper, liquidityAmount);

        assertGt(amount0, 0);
        assertGt(amount1, 0);
    }

    // --- NEW SWAP TEST ---
    function test_Swap_Token0_For_Token1() public {
        uint160 startingPrice = pool.sqrtPriceX96();

        // Define a price limit (new price after swap)
        uint160 priceLimit = startingPrice - 10000;

        // Perform the swap
        (int256 amount0, int256 amount1) = pool.swap(address(this), true, 1e18, priceLimit);

        // Check that we received token1 and sent token0
        assertGt(amount1, 0);
        assertLt(amount0, 0);

        // Check that the price has decreased
        assertLt(pool.sqrtPriceX96(), startingPrice);
    }
}