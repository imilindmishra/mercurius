// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IMercuriusPool} from "./interfaces/IMercuriusPool.sol";
import {IMercuriusFactory} from "./interfaces/IMercuriusFactory.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256) external;
}

contract Router {
    address public immutable factory;
    address public immutable WETH9;

    constructor(address _factory, address _WETH9) {
        factory = _factory;
        WETH9 = _WETH9;
    }

    struct SwapParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint160 sqrtPriceLimitX96;
    }

    function swapExactInputSingle(SwapParams memory params)
        external
        payable
        returns (uint256 amountOut)
    {
        // This part for native ETH swaps is fine
        if (msg.value > 0) {
            IWETH(WETH9).deposit{value: msg.value}();
        }

        // Sort tokens for pool lookup
        address token0 = params.tokenIn < params.tokenOut ? params.tokenIn : params.tokenOut;
        address token1 = params.tokenIn < params.tokenOut ? params.tokenOut : params.tokenIn;

        address pool = IMercuriusFactory(factory).getPool(
            token0,
            token1,
            params.fee
        );
        require(pool != address(0), "P");

        
        // CORRECTED: Pull tokens from the user (msg.sender) who approved the router, and send them to the pool.
        IERC20(params.tokenIn).transferFrom(msg.sender, pool, params.amountIn);

        bool zeroForOne = params.tokenIn < params.tokenOut;
        (int256 amount0, int256 amount1) = IMercuriusPool(pool).swap(
            params.recipient,
            zeroForOne,
            params.amountIn,
            params.sqrtPriceLimitX96
        );

        amountOut = zeroForOne ? uint256(amount1) : uint256(amount0);
    }
}