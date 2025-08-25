// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FullMath} from "./FullMath.sol";

library SqrtPriceMath {
    function getAmount0Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        uint256 num = uint256(liquidity) << 96;
        uint256 den = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, 1 << 96);
        amount0 = FullMath.mulDiv(num, sqrtRatioBX96 - sqrtRatioAX96, den);
    }

    function getAmount1Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        
        amount1 = FullMath.mulDiv(
            liquidity,
            sqrtRatioBX96 - sqrtRatioAX96,
            1 << 96
        );
    }

    function getNextSqrtPriceFromInput(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amountIn,
        bool zeroForOne
    ) internal pure returns (uint160 sqrtPriceNextX96) {
        if (zeroForOne) {
            uint256 num = uint256(liquidity) << 96;
            uint256 den = liquidity + FullMath.mulDiv(amountIn, sqrtPX96, 1 << 96);
            sqrtPriceNextX96 = uint160(FullMath.mulDiv(num, sqrtPX96, den));
        } else {
            sqrtPriceNextX96 = uint160(
                sqrtPX96 + (amountIn << 96) / liquidity
            );
        }
    }
}