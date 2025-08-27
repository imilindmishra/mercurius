// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IMercuriusFactory} from "./interfaces/IMercuriusFactory.sol";
import {MercuriusPool} from "./MercuriusPool.sol";

contract MercuriusFactory is IMercuriusFactory {
    // Mapping to store created pools
    mapping(address => mapping(address => mapping(uint24 => address)))
        public override getPool;

    // Struct to hold pool parameters temporarily during creation
    struct PoolParameters {
        address factory;
        address token0;
        address token1;
        uint24 fee;
        int24 initialTick;
    }

    PoolParameters public override parameters;

    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee,
        int24 initialTick
    ) external returns (address pool) {
        require(tokenA != tokenB, "IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "ZERO_ADDRESS");

        require(getPool[token0][token1][fee] == address(0), "POOL_EXISTS");

        parameters = PoolParameters({
            factory: address(this),
            token0: token0,
            token1: token1,
            fee: fee,
            initialTick: initialTick
        });
        
        pool = address(new MercuriusPool());
        getPool[token0][token1][fee] = pool;

        // Clear the parameters after creation
        delete parameters;
    }
}