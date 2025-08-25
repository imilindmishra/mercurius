// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMercuriusFactory {
    // Returns the pool address for a given pair of tokens and a fee
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);
        
    // Returns the parameters of the factory, called by the pool constructor
    function parameters()
        external
        view
        returns (
            address factory,
            address token0,
            address token1,
            uint24 fee,
            int24 tickSpacing
        );
}