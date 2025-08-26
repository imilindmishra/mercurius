// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Position} from "../libraries/Position.sol";
import {Tick} from "../libraries/Tick.sol";

interface IMercuriusPool {
    struct Slot0 {
        // The current price of the pool
        uint160 sqrtPriceX96;
        // The current tick of the pool
        int24 tick;
    }

    // Public state variables
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function fee() external view returns (uint24);
    function liquidity() external view returns (uint128);
    function slot0() external view returns (uint160 sqrtPriceX96, int24 tick);
    function ticks(int24 tick) external view returns (uint128 liquidityGross, int128 liquidityNet);
    function positions(bytes32 key) external view returns (uint128 liquidity);
    
    
    function tickBitmap(int16 word) external view returns (uint256);

    // Public functions
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    function swap(
        address recipient,
        bool zeroForOne,
        uint256 amountSpecified,
        uint160 sqrtPriceLimitX96
    ) external returns (int256 amount0, int256 amount1);
}