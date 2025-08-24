// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMercuriusPool {
    function mint(address recipient, int24 tickLower, int24 tickUpper, uint128 amount) external returns (uint256 amount0, uint256 amount1);
    function swap(address recipient, bool zeroForOne, uint256 amountSpecified, uint160 sqrtPriceLimitX96) external returns (int256 amount0, int256 amount1);
}