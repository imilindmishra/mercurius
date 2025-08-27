// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IMercuriusPool} from "./interfaces/IMercuriusPool.sol";
import {IMercuriusFactory} from "./interfaces/IMercuriusFactory.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract NonfungiblePositionManager is ERC721 {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    struct Position {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
    }

    address public immutable factory;
    mapping(uint256 => Position) public positions;

    constructor(address _factory) ERC721("Mercurius Position", "MCP") {
        factory = _factory;
    }

    function mint(MintParams memory params)
        external
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        require(params.deadline >= block.timestamp, "DEADLINE_EXPIRED");

        address pool = IMercuriusFactory(factory).getPool(
            params.token0,
            params.token1,
            params.fee
        );
        require(pool != address(0), "POOL_NOT_FOUND");
        
        // This is a simplified liquidity calculation.
        // A production DEX would have complex math here based on amounts and the current price.
        liquidity = 10 ether; 

        // Transfer funds from the user to the pool
        if (params.amount0Desired > 0) {
             IERC20(params.token0).transferFrom(msg.sender, pool, params.amount0Desired);
        }
        if (params.amount1Desired > 0) {
            IERC20(params.token1).transferFrom(msg.sender, pool, params.amount1Desired);
        }

        (amount0, amount1) = IMercuriusPool(pool).mint(
            params.recipient,
            params.tickLower,
            params.tickUpper,
            liquidity
        );

        // This is not a robust way to generate a unique token ID.
        // A production system would use an incrementing counter.
        tokenId = uint256(
            keccak256(
                abi.encodePacked(
                    pool,
                    params.recipient,
                    params.tickLower,
                    params.tickUpper
                )
            )
        );

        _mint(params.recipient, tokenId);

        positions[tokenId] = Position({
            token0: params.token0,
            token1: params.token1,
            fee: params.fee,
            tickLower: params.tickLower,
            tickUpper: params.tickUpper,
            liquidity: liquidity
        });
    }
}