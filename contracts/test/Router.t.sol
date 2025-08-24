// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MercuriusFactory} from "../src/MercuriusFactory.sol";
import {MercuriusPool} from "../src/MercuriusPool.sol";
import {NonfungiblePositionManager} from "../src/NonfungiblePositionManager.sol";
import {Router} from "../src/Router.sol";
import {TickMath} from "../src/libraries/TickMath.sol";

contract RouterTest is Test {
    MercuriusFactory factory;
    NonfungiblePositionManager nfpm;
    Router router;
    address pool;

    address internal constant TOKEN_A = address(0x1);
    address internal constant TOKEN_B = address(0x2);
    uint24 internal constant FEE = 3000;
    uint160 internal constant INITIAL_PRICE = 79228162514264337593543950336;

    function setUp() public {
        factory = new MercuriusFactory();
        nfpm = new NonfungiblePositionManager(address(factory));
        router = new Router(address(factory));
        pool = factory.createPool(TOKEN_A, TOKEN_B, FEE, INITIAL_PRICE);

        // Provide initial liquidity for the pool
        nfpm.mint(TOKEN_A, TOKEN_B, FEE, TickMath.MIN_TICK, TickMath.MAX_TICK, 10 ether);
    }

    function test_SwapExactInputSingle() public {
        uint256 amountIn = 1 ether;

        // Define swap parameters
        Router.SwapParams memory params = Router.SwapParams({
            tokenIn: TOKEN_A,
            tokenOut: TOKEN_B,
            fee: FEE,
            recipient: address(this),
            amountIn: amountIn,
            sqrtPriceLimitX96: INITIAL_PRICE - 1000 // Price limit for the swap
        });

        // Execute swap through the router
        uint256 amountOut = router.swapExactInputSingle(params);

        // Check that we received some amount of the output token
        assertGt(amountOut, 0);
    }
}