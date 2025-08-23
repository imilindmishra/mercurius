// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library Tick {
    // info shared for each tick
    struct Info {
        uint128 liquidityGross;
        uint128 liquidityNet;
    }
}