// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library LiquidityMath {
    function addDelta(uint128 x, int128 y) internal pure returns (uint128 z) {
        if (y < 0) {
            uint128 sub = uint128(-y);
            require(x >= sub, "LS");
            z = x - sub;
        } else {
            z = x + uint128(y);
            require(z >= x, "LA");
        }
    }
}