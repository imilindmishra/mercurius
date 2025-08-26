// contracts/src/libraries/TickBitmap.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library TickBitmap {
    function position(int24 tick) private pure returns (int16 wordPos, uint8 bitPos) {
        wordPos = int16(tick >> 8);
        bitPos = uint8(uint24(tick % 256));
    }

    function flipTick(
        mapping(int16 => uint256) storage self,
        int24 tick
    ) internal {
        (int16 wordPos, uint8 bitPos) = position(tick);
        uint256 mask = 1 << bitPos;
        self[wordPos] ^= mask;
    }

    function nextInitializedTickWithinOneWord(
        mapping(int16 => uint256) storage self,
        int24 tick,
        int24 tickSpacing,
        bool lte
    ) internal view returns (int24 next, bool initialized) {
        int24 compressed = tick / tickSpacing;

        if (lte) {
            (int16 wordPos, uint8 bitPos) = position(compressed);
            uint256 mask = (1 << bitPos) - 1 + (1 << bitPos);
            uint256 masked = self[wordPos] & mask;

            if (masked != 0) {
                uint256 highestBit = 255 - clz(masked);
                // CORRECTED: Added intermediate cast to int256
                int24 nextCompressed = (int24(wordPos) << 8) + int24(int256(highestBit));
                next = nextCompressed * tickSpacing;
            } else {
                next = (int24(wordPos) - 1) * tickSpacing;
            }
        } else {
            (int16 wordPos, uint8 bitPos) = position(compressed + 1);
            uint256 mask = ~((1 << bitPos) - 1);
            uint256 masked = self[wordPos] & mask;
            
            if (masked != 0) {
                 uint256 lowestBit = ctz(masked);
                 // CORRECTED: Added intermediate cast to int256
                 int24 nextCompressed = (int24(wordPos) << 8) + int24(int256(lowestBit));
                 next = nextCompressed * tickSpacing;
            } else {
                next = (int24(wordPos) + 1) * tickSpacing;
            }
        }

        initialized = true;
    }

    function clz(uint256 x) private pure returns (uint256) {
        uint256 n = 0;
        if (x == 0) return 256;
        if (x <= 0x0000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) { n += 128; x <<= 128; }
        if (x <= 0x00000000FFFFFFFFFFFFFFFFFFFFFFFF) { n += 64; x <<= 64; }
        if (x <= 0x0000FFFFFFFFFFFF) { n += 32; x <<= 32; }
        if (x <= 0xFFFFFFFF) { n += 16; x <<= 16; }
        if (x <= 0xFFFF) { n += 8; x <<= 8; }
        if (x <= 0xFF) { n += 4; x <<= 4; }
        if (x <= 0xF) { n += 2; x <<= 2; }
        if (x <= 0x3) { n += 1; }
        return n;
    }

    function ctz(uint256 x) private pure returns (uint256) {
        if (x == 0) return 256;
        uint256 n = 255;
        uint256 y;
        y = x << 128; if (y != 0) { n -= 128; x = y; }
        y = x << 64; if (y != 0) { n -= 64; x = y; }
        y = x << 32; if (y != 0) { n -= 32; x = y; }
        y = x << 16; if (y != 0) { n -= 16; x = y; }
        y = x << 8; if (y != 0) { n -= 8; x = y; }
        y = x << 4; if (y != 0) { n -= 4; x = y; }
        y = x << 2; if (y != 0) { n -= 2; x = y; }
        y = x << 1; if (y != 0) { n -= 1; }
        return n;
    }
}