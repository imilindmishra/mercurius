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

    function computeSwapStep(
        uint160 sqrtRatioCurrentX96,
        uint160 sqrtRatioTargetX96,
        uint128 liquidity,
        uint256 amountRemaining,
        uint24 feePips
    ) internal pure returns (ComputeSwapStepResult memory) {
        bool zeroForOne = sqrtRatioCurrentX96 > sqrtRatioTargetX96;
        
        uint256 amountIn;
        uint256 amountOut;
        
        // Calculate amountIn and amountOut based on the direction of the swap
        if (zeroForOne) {
            // Formula for swapping token0 for token1 (price decreases)
            amountIn = SqrtPriceMath.getAmount0Delta(
                sqrtRatioTargetX96,
                sqrtRatioCurrentX96,
                liquidity
            );
        } else {
            // Formula for swapping token1 for token0 (price increases)
            amountIn = SqrtPriceMath.getAmount1Delta(
                sqrtRatioTargetX96,
                sqrtRatioCurrentX96,
                liquidity
            );
        }

        // Calculate fee on the input amount
        uint256 feeAmount = (amountIn * feePips) / 1_000_000;
        
        // Check if there is enough amountRemaining to cover the calculated amountIn + fee
        if (amountRemaining >= amountIn + feeAmount) {
            // If yes, we use the target price as the next price
            if (zeroForOne) {
                amountOut = SqrtPriceMath.getAmount1Delta(
                    sqrtRatioTargetX96,
                    sqrtRatioCurrentX96,
                    liquidity
                );
            } else {
                amountOut = SqrtPriceMath.getAmount0Delta(
                    sqrtRatioTargetX96,
                    sqrtRatioCurrentX96,
                    liquidity
                );
            }
            return ComputeSwapStepResult({
                sqrtRatioNextX96: sqrtRatioTargetX96,
                amountIn: amountIn,
                amountOut: amountOut,
                feeAmount: feeAmount
            });
        } else {
            // If not enough amountRemaining, we calculate the next price based on what's left
            uint160 sqrtRatioNextX96 = SqrtPriceMath.getNextSqrtPriceFromInput(
                sqrtRatioCurrentX96,
                liquidity,
                amountRemaining,
                zeroForOne
            );

            if (zeroForOne) {
                amountOut = SqrtPriceMath.getAmount1Delta(
                    sqrtRatioNextX96,
                    sqrtRatioCurrentX96,
                    liquidity
                );
            } else {
                amountOut = SqrtPriceMath.getAmount0Delta(
                    sqrtRatioNextX96,
                    sqrtRatioCurrentX96,
                    liquidity
                );
            }
            
            // Recalculate fee based on the actual amount used
            feeAmount = (amountRemaining * feePips) / 1_000_000;

            return ComputeSwapStepResult({
                sqrtRatioNextX96: sqrtRatioNextX96,
                amountIn: amountRemaining - feeAmount,
                amountOut: amountOut,
                feeAmount: feeAmount
            });
        }
    }
}