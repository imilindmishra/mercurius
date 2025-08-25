// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LiquidityMath} from "./LiquidityMath.sol";

library Tick {
    struct Info {
        uint128 liquidityGross;
        int128 liquidityNet;
    }

    // The library `using` statement will be on mapping(int24 => Tick.Info)
    // so the first argument `self` will be the mapping.
    function update(
        mapping(int24 => Tick.Info) storage self,
        int24 tick,
        int24 currentTick,
        uint128 liquidityDelta,
        bool upper
    ) internal {
        Info storage info = self[tick];
        uint128 liquidityGrossBefore = info.liquidityGross;
        uint128 liquidityGrossAfter = LiquidityMath.addDelta(
            liquidityGrossBefore,
            int128(liquidityDelta)
        );

        info.liquidityGross = liquidityGrossAfter;

        if (tick <= currentTick) {
            info.liquidityNet = upper
                ? info.liquidityNet - int128(liquidityDelta)
                : info.liquidityNet + int128(liquidityDelta);
        }
    }

    function cross(
        mapping(int24 => Tick.Info) storage self,
        int24 tick,
        bool isZeroForOne
    ) internal view returns (int128 liquidityDelta) {
        Info storage info = self[tick];
        liquidityDelta = isZeroForOne ? info.liquidityNet : -info.liquidityNet;
    }
}