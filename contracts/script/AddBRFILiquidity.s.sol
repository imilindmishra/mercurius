// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {IMercuriusPool} from "../src/interfaces/IMercuriusPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// You'll need to add this to your IMercuriusPool interface
interface IPoolState {
    function slot0() external view returns (
        uint160 sqrtPriceX96,
        int24 tick,
        uint16 observationIndex,
        uint16 observationCardinality,
        uint16 observationCardinalityNext,
        uint8 feeProtocol,
        bool unlocked
    );
}

contract AddBRFILiquidity is Script {
    function run() external {
        // Hardcoded values
        address poolAddr = 0xd0335A436A34278fe380C5997152DB21F1DA7A10;
        address token0 = 0x3C8Dd7870E9a8e7e996543C4ADeB643438D4Aba8;  // KAJU
        address token1 = 0xE6DC9225E4C76f9c0b002Ab2782F687e35cc7666;  // BRFI
        uint128 amount = 1000000000000000;  // 1e15 for liquidity
        
        vm.startBroadcast();
        
        IMercuriusPool pool = IMercuriusPool(poolAddr);
        IPoolState poolState = IPoolState(poolAddr);
        
        // Get current tick
        (, int24 currentTick, , , , , ) = poolState.slot0();
        console.log("Current pool tick:", currentTick);
        
        // Approve tokens to pool
        IERC20(token0).approve(poolAddr, type(uint256).max);
        IERC20(token1).approve(poolAddr, type(uint256).max);
        
        // Set range above current price to require BRFI
        int24 lowerTick = currentTick + 1000;   // Above current price
        int24 upperTick = currentTick + 5000;   // Well above current price
        
        console.log("Setting lower tick:", lowerTick);
        console.log("Setting upper tick:", upperTick);
        
        // Mint liquidity
        (uint256 amt0, uint256 amt1) = pool.mint(
            msg.sender, 
            lowerTick,
            upperTick,
            amount
        );
        
        console.log("Mint returned amt0:", amt0);
        console.log("Mint returned amt1:", amt1);
        
        // This should now require BRFI
        require(amt1 > 0, "No BRFI added - range calculation error");
        
        // Only transfer if amounts are positive
        if (amt0 > 0) {
            IERC20(token0).transfer(poolAddr, amt0);
        }
        if (amt1 > 0) {
            IERC20(token1).transfer(poolAddr, amt1);
        }
        
        console.log("Successfully added liquidity - KAJU:", amt0);
        console.log("Successfully added liquidity - BRFI:", amt1);
        vm.stopBroadcast();
    }
}