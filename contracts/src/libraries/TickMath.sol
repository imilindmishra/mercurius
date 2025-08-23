// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Math library for computing ticks from prices and vice versa
library TickMath {
    /// @dev The minimum tick that may be used
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be used
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @notice The minimum value of SqrtRatioX96
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @notice The maximum value of SqrtRatioX96
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Gets the tick corresponding to a given sqrt ratio, s.t. log base 1.0001 of sqrt(p)
    /// @param sqrtPriceX96 The sqrt ratio as a Q64.96 fixed point number
    /// @return tick The tick corresponding to the price
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // This function is implemented using a lookup table for efficiency.
        // The full implementation is very long; for our purpose, we will use a simplified logic.
        // A real implementation would use binary search on a pre-calculated table.
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 <= MAX_SQRT_RATIO, "R");

        // Simplified stub for this example. A full implementation is highly complex.
        // For now, we'll return a value based on a simple calculation.
        // This is NOT the real Uniswap V3 formula but serves our structural purpose.
        uint256 ratio = (uint256(sqrtPriceX96) * uint256(sqrtPriceX96)) >> (96 * 2);
        tick = int24(int256(ratio)); // Example conversion
    }
}