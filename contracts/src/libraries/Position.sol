// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LiquidityMath} from "./LiquidityMath.sol";

library Position {
    struct Info {
        uint128 liquidity;
    }

    function update(
        mapping(bytes32 => Info) storage self,
        bytes32 key,
        uint128 liquidityDelta
    ) internal {
        Info storage pos = self[key];
        pos.liquidity = LiquidityMath.addDelta(
            pos.liquidity,
            int128(liquidityDelta)
        );
    }
}