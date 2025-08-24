// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20; 

library SqrtPriceMath {

    function getAmount0Delta(uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint128 liquidity)
    internal pure returns ( uint256 amount0 ) {
        if ( sqrtRatioAX96 > sqrtRatioBX96 ) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        // Simplified calculation
    // round up to avoid returning 0 for small deltas
    uint256 num0 = uint256(liquidity) * (uint256(sqrtRatioBX96) - uint256(sqrtRatioAX96));
    amount0 = (num0 + uint256(sqrtRatioAX96) - 1) / uint256(sqrtRatioAX96);
    }

    function getAmount1Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

    // Simplified calculation with rounding up to avoid zero
    uint256 num1 = uint256(liquidity) * (uint256(sqrtRatioBX96) - uint256(sqrtRatioAX96));
    uint256 denom = uint256(1) << 96;
    amount1 = (num1 + denom - 1) >> 96;
    }
}