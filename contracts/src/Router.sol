// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IMercuriusPool} from "./interfaces/IMercuriusPool.sol";
import {IMercuriusFactory} from "./interfaces/IMercuriusFactory.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract Router {
    address public immutable factory;

    constructor(address _factory) {
        factory = _factory;
    }

    struct SwapParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint160 sqrtPriceLimitX96;
    }

    function swapExactInputSingle(SwapParams memory params) external returns (uint256 amountOut) {

        //transfer the input token from the user to the pool
        address pool = IMercuriusFactory(factory).getPool(params.tokenIn, params.tokenOut, params.fee);
        require(pool != address(0), "P");

        bool zeroForOne = params.tokenIn < params.tokenOut;

        //call the swap function on the pool
    (int256 amount0, int256 amount1) = IMercuriusPool(pool).swap(
            params.recipient,
            zeroForOne,
            params.amountIn,
            params.sqrtPriceLimitX96
        );

        return zeroForOne ? uint256(-amount1) : uint256(-amount0);
    }
}

