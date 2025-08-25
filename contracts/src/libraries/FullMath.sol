// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library FullMath {
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        uint256 p = a * b;
        result = p / denominator;
        if (p % denominator > 0) {
            // This is a simplified rounding up. 
            // A production-ready contract might use a more sophisticated rounding method.
            result += 1;
        }
    }
}