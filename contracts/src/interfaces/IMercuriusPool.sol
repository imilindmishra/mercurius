// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMercuriusPool {
    function mint(address recipient, int24 tickLower, int24 tickUpper, uint128 amount) external returns (uint256 amount0, uint256 amount1);
}