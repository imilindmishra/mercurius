// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MercuriusFactory} from "../src/MercuriusFactory.sol";
import {MercuriusPool} from "../src/MercuriusPool.sol";
import {NonfungiblePositionManager} from "../src/NonfungiblePositionManager.sol";
import {TickMath} from "../src/libraries/TickMath.sol";

contract NFPMTest is Test {
    MercuriusFactory factory;
    NonfungiblePositionManager nfpm;
    address pool;

    address internal constant TOKEN_A = address(0x1);
    address internal constant TOKEN_B = address(0x2);
    uint24 internal constant FEE = 3000;
    uint160 internal constant INITIAL_PRICE = 79228162514264337593543950336;

    function setUp() public {
        // 1. Deploy the factory
        factory = new MercuriusFactory();

        // 2. Deploy the NFPM, linking it to the factory
        nfpm = new NonfungiblePositionManager(address(factory));

        // 3. Use the factory to create a pool
        pool = factory.createPool(TOKEN_A, TOKEN_B, FEE, INITIAL_PRICE);
    }

    function test_MintNewPosition() public {
        uint128 liquidityAmount = 100;
        int24 tickLower = -10;
        int24 tickUpper = 10;

        // Mint a new position through the NFPM
        uint256 tokenId = nfpm.mint(TOKEN_A, TOKEN_B, FEE, tickLower, tickUpper, liquidityAmount);

        // 1. Check if the NFT was minted to the correct owner (the test contract)
        assertEq(nfpm.ownerOf(tokenId), address(this));

        // 2. Check if the position details were stored correctly
        NonfungiblePositionManager.Position memory pos = nfpm.positions(tokenId);
        assertEq(pos.liquidity, liquidityAmount);
        assertEq(pos.tickLower, tickLower);
    }
}