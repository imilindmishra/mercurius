// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SqrtPriceMath} from "./SqrtPriceMath.sol";

library SwapMath {
    struct ComputeSwapStepResult {
        uint160 sqrtRatioNextX96;
        uint256 amountIn;
        uint256 amountOut;
        uint256 feeAmount;
    }

    // Computes the result of a swap within a single tick range
    function computeSwapStep(
        uint160 sqrtRatioCurrentX96,
        uint160 sqrtRatioTargetX96,
        uint128 liquidity,
        uint256 amountRemaining,
        uint24 feePips
    ) internal pure returns (ComputeSwapStepResult memory) {

        uint256 amountIn = SqrtPriceMath.getAmount0Delta(sqrtRatioTargetX96, sqrtRatioCurrentX96, liquidity);
        uint256 amountOut = SqrtPriceMath.getAmount1Delta(sqrtRatioTargetX96, sqrtRatioCurrentX96, liquidity);

        return ComputeSwapStepResult({
            sqrtRatioNextX96: sqrtRatioTargetX96,
            amountIn: amountIn,
            amountOut: amountOut,
            feeAmount: 0
        });
    }
}