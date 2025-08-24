// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMercuriusFactory {
    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool);
}