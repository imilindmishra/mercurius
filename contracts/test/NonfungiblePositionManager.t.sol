// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MercuriusFactory} from "../src/MercuriusFactory.sol";
import {NonfungiblePositionManager} from "../src/NonfungiblePositionManager.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract NonfungiblePositionManagerTest is Test {
    MercuriusFactory factory;
    NonfungiblePositionManager nfpm;
    address pool;

    // We'll use the same Optimism Sepolia addresses for consistency
    address constant WETH = 0x4200000000000000000000000000000000000006;
    address constant USDC = 0x7E07E15D2a87A24492740D16f5bdF58c16db0c4E;
    uint24 constant FEE = 3000;
    int24 constant START_TICK = 207218;

    function setUp() public {
        factory = new MercuriusFactory();
        nfpm = new NonfungiblePositionManager(address(factory));
        pool = factory.createPool(WETH, USDC, FEE, START_TICK);
    }

    function testMintNewPosition() public {
        // Use Foundry's `deal` cheatcode to give this test contract some test tokens
        uint256 wethAmount = 1 ether;
        uint256 usdcAmount = 3000 * 1e6; // 3000 USDC (6 decimals)
        deal(WETH, address(this), wethAmount);
        deal(USDC, address(this), usdcAmount);

        // Approve the NonfungiblePositionManager to spend our tokens
        IERC20(WETH).approve(address(nfpm), wethAmount);
        IERC20(USDC).approve(address(nfpm), usdcAmount);

        // Construct the MintParams struct, which is the single argument for mint()
        NonfungiblePositionManager.MintParams memory params = NonfungiblePositionManager
            .MintParams({
                token0: WETH,
                token1: USDC,
                fee: FEE,
                tickLower: START_TICK - 100,
                tickUpper: START_TICK + 100,
                amount0Desired: wethAmount,
                amount1Desired: usdcAmount,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp + 60
            });

        // Call mint and capture all 4 return values
        (uint256 tokenId, uint128 liquidity, , ) = nfpm.mint(params);

        // Assert that the mint was successful
        assertTrue(tokenId > 0, "Token ID should be greater than 0");
        assertTrue(liquidity > 0, "Liquidity should be greater than 0");
        assertEq(nfpm.ownerOf(tokenId), address(this), "Owner should be the test contract");

        // Correctly read the position struct from the public mapping
        (
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 posLiquidity
        ) = nfpm.positions(tokenId);
        
        assertEq(token0, WETH, "Position token0 is incorrect");
        assertEq(token1, USDC, "Position token1 is incorrect");
        assertEq(fee, FEE, "Position fee is incorrect");
        assertEq(tickLower, START_TICK - 100, "Position tickLower is incorrect");
        assertEq(tickUpper, START_TICK + 100, "Position tickUpper is incorrect");
        assertEq(posLiquidity, liquidity, "Position liquidity is incorrect");
    }
}