// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20; 

library SqrtPriceMath {

    function getAmount0Delta(uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint128 liquidity)
    internal pure returns ( uint256 amount0 ) {
        if ( sqrtRatioAX96 > sqrtRatioBX96 ) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        // Simplified calculation
        amount0 = (uint256(liquidity) * (sqrtRatioBX96 - sqrtRatioAX96)) / sqrtRatioAX96;
    }

    function getAmount1Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        // Simplified calculation
        amount1 = (uint256(liquidity) * (sqrtRatioBX96 - sqrtRatioAX96)) >> 96;    
    }
}