// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LiquidityMath} from "./LiquidityMath.sol";

library Position {
    struct Info {
        uint128 liquidity;
    }

    function update(
        Info storage self,
        int128 liquidityDelta
    ) internal {
        uint128 liquidityBefore = self.liquidity;
        uint128 liquidityAfter = LiquidityMath.addDelta(liquidityBefore, liquidityDelta);
        self.liquidity = liquidityAfter;
    }
}