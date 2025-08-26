// contracts/src/Router.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IMercuriusPool} from "./interfaces/IMercuriusPool.sol";
import {IMercuriusFactory} from "./interfaces/IMercuriusFactory.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// Interface for WETH
interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256) external;
}

contract Router {
    address public immutable factory;
    address public immutable WETH9; // Address of the WETH contract

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

    // Making this function payable allows it to receive native ETH
    function swapExactInputSingle(SwapParams memory params)
        external
        payable
        returns (uint256 amountOut)
    {
        // If ETH is sent with the transaction, deposit it to get WETH
        if (msg.value > 0) {
            IWETH(WETH9).deposit{value: msg.value}();
            require(IWETH(WETH9).transfer(address(this), msg.value), "WETH_TRANSFER_FAILED");
        }

        address pool = IMercuriusFactory(factory).getPool(
            params.tokenIn,
            params.tokenOut,
            params.fee
        );
        require(pool != address(0), "P"); // Pool must exist

        // Transfer tokens to the pool and get the output amount
        IERC20(params.tokenIn).transfer(pool, params.amountIn);

        (int256 amount0, int256 amount1) = IMercuriusPool(pool).swap(
            params.recipient,
            params.tokenIn < params.tokenOut,
            params.amountIn,
            params.sqrtPriceLimitX96
        );

        return params.tokenIn < params.tokenOut ? uint256(-amount1) : uint256(-amount0);
    }
}