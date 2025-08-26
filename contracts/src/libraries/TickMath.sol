// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library TickMath {
    /// The minimum tick that may be used on any pool.
    int24 public constant MIN_TICK = -887272;
    /// The maximum tick that may be used on any pool.
    int24 public constant MAX_TICK = -MIN_TICK;

    /// The minimum square root of price, representing the price of 1 wei of token1 against the max wei of token0
    uint160 public constant MIN_SQRT_RATIO = 4295128739;
    /// The maximum square root of price, representing the max wei of token1 against 1 wei of token0
    uint160 public constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Gets the tick corresponding to a given square root of a price
    /// @param sqrtRatioX96 The square root of the price for which to compute the tick
    /// @return tick The tick corresponding to the price
    function getTickAtSqrtRatio(uint160 sqrtRatioX96) internal pure returns (int24 tick) {
        uint256 ratio = uint256(sqrtRatioX96) * uint256(sqrtRatioX96);
        uint256 r;
        if (ratio > (1 << 192)) {
            r = ratio >> 192;
            // CORRECTED: Added intermediate cast to int256
            tick = int24(int256(22188 + (log2(r) * 66438)));
        } else {
            r = (1 << 192) / ratio;
            // CORRECTED: Added intermediate cast to int256
            tick = -int24(int256(22188 + (log2(r) * 66438)));
        }
    }

    /// @notice Gets the square root of the price for a given tick
    /// @param tick The tick for which to compute the square root of the price
    /// @return sqrtRatioX96 The square root of the price
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtRatioX96) {
        // CORRECTED: Cast via int256 to get absolute value safely
        uint256 absTick = uint256(int256(tick < 0 ? -tick : tick));
        uint256 ratio = (absTick & 0x1) != 0 ? 0xfffcb933bd6a47a6d234a34eefb8a5b8 : 0x100000000000000000000000000000000;
        if ((absTick & 0x2) != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if ((absTick & 0x4) != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if ((absTick & 0x8) != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if ((absTick & 0x10) != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if ((absTick & 0x20) != 0) ratio = (ratio * 0xff973b41fa98c081472de089225f4258) >> 128;
        if ((absTick & 0x40) != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if ((absTick & 0x80) != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if ((absTick & 0x100) != 0) ratio = (ratio * 0xfcbe86c75d6ced848f3002d0849e3c2c) >> 128;
        if ((absTick & 0x200) != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e94) >> 128;
        if ((absTick & 0x400) != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if ((absTick & 0x800) != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if ((absTick & 0x1000) != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if ((absTick & 0x2000) != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if ((absTick & 0x4000) != 0) ratio = (ratio * 0x70d869a150d43a697ce6d9fa208346c5) >> 128;
        if ((absTick & 0x8000) != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if ((absTick & 0x10000) != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e990ac) >> 128;
        if ((absTick & 0x20000) != 0) ratio = (ratio * 0x5d62ae4a042ee69a718972781b2b834) >> 128;
        if ((absTick & 0x40000) != 0) ratio = (ratio * 0x226809702ab94553c25b29ddc27598) >> 128;
        if ((absTick & 0x80000) != 0) ratio = (ratio * 0x48a170391f7dc41) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        sqrtRatioX96 = uint160(ratio >> 96);
    }
    
    function log2(uint256 x) private pure returns (uint256) {
        uint256 n = 0;
        if (x >= 0x100000000000000000000000000000000) { n += 128; x >>= 128; }
        if (x >= 0x10000000000000000) { n += 64; x >>= 64; }
        if (x >= 0x100000000) { n += 32; x >>= 32; }
        if (x >= 0x10000) { n += 16; x >>= 16; }
        if (x >= 0x100) { n += 8; x >>= 8; }
        if (x >= 0x10) { n += 4; x >>= 4; }
        if (x >= 0x4) { n += 2; x >>= 2; }
        if (x >= 0x2) { n += 1; }
        return n;
    }
}