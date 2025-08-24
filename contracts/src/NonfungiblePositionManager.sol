// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721.sol";
import {IMercuriusFactory} from "./interfaces/IMercuriusFactory.sol";
import {IMercuriusPool} from "./interfaces/IMercuriusPool.sol";

contract NonfungiblePositionManager is ERC721 {
    struct Position {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
    }

    //factory contract address
    address public immutable factory;
    
    //tokenID to position mapping
    mapping(uint256 => Position) public positions;

    constructor(address _factory) ERC721("Mercurius Position", "MCP") {
        factory = _factory;
    }

    //Mints a new position NFT
    function mint(
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidityAmount
    ) external returns (uint256 tokenId) {
        //Get pool address from factory
        address pool = IMercuriusFactory(factory).getPool(token0, token1, fee);
        require(pool != address(0), "PIE");

        //call the mint function
        IMercuriusPool(pool).mint(msg.sender, tickLower, tickUpper, liquidityAmount);
        
        //get next available tokenId
        tokenId = uint256(keccak256(abi.encodePacked(pool, msg.sender, tickLower, tickUpper)));

        // Mint the NFT to the user
        _mint(msg.sender, tokenId);

        // store the position's details
        positions[tokenId] = Position({
            token0: token0,
            token1: token1,
            fee: fee,
            tickLower: tickLower,
            tickUpper: tickUpper,
            liquidity: liquidityAmount
        });
    }
    
}