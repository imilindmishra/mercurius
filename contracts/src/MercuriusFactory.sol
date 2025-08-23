// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {MercuriusPool} from "./MercuriusPool.sol";

contract MercuriusFactory is Ownable {

    // Event jo emit hoga jab bhi naya pool banega
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        address pool
    );

    // Mapping to store addresses of all created pools
    // getPool[tokenA][tokenB][fee] => poolAddress
    mapping(address => mapping(address => mapping(uint24 => address))) public getPool;

    constructor() Ownable(msg.sender) {}

    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee,
        uint160 sqrtPriceX96Initial
    ) external onlyOwner returns (address pool) {
        require(tokenA != tokenB, "IDENTICAL_ADDRESSES"); 

        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        require(getPool[token0][token1][fee] == address(0), "POOL_EXISTS");

        pool = address(new MercuriusPool(token0, token1, fee, sqrtPriceX96Initial));
        getPool[token0][token1][fee] = pool;

        emit PoolCreated(token0, token1, fee, pool);
    }
}