// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library TickBitmap {
    //returns a point in a bitmap array and the bit within uint256
    function position(int24 tick) private pure returns (int16 wordPos, uint8 bitPos) {
        wordPos = int16(tick >> 8);
        bitPos = uint8(uint24(tick % 256));
    }

    //flipping the bit in the bitmap
    function flipTick(mapping(int16 => uint256) storage self, int24 tick) internal {
        (int16 wordPos, uint8 bitPos) = position(tick);
        uint256 mask = 1 << bitPos;
        self[wordPos] ^= mask;
    }
}