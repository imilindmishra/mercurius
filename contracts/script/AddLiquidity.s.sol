// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {IMercuriusPool} from "../src/interfaces/IMercuriusPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RebalancePool is Script {
    function run() external {
        address poolAddr = 0xd0335A436A34278fe380C5997152DB21F1DA7A10;
        address token0 = 0x3C8Dd7870E9a8e7e996543C4ADeB643438D4Aba8; // Kaju
        address token1 = 0xE6DC9225E4C76f9c0b002Ab2782F687e35cc7666; // BRFI
        
        vm.startBroadcast();
        
        console.log("=== POOL REBALANCING SCRIPT ===");
        
        // Check current token balances in pool
        uint256 pool_token0_balance = IERC20(token0).balanceOf(poolAddr);
        uint256 pool_token1_balance = IERC20(token1).balanceOf(poolAddr);
        
        console.log("Current pool balances:");
        console.log("  Token0 (Kaju):", pool_token0_balance);
        console.log("  Token1 (BRFI):", pool_token1_balance);
        
        // Check your wallet balances
        uint256 wallet_token0_balance = IERC20(token0).balanceOf(msg.sender);
        uint256 wallet_token1_balance = IERC20(token1).balanceOf(msg.sender);
        
        console.log("Your wallet balances:");
        console.log("  Token0 (Kaju):", wallet_token0_balance);
        console.log("  Token1 (BRFI):", wallet_token1_balance);
        
        // Strategy: Add liquidity in a way that forces both tokens
        // Option 1: Try adding liquidity that spans negative to positive ticks
        console.log("\n=== ATTEMPTING REBALANCE ===");
        
        if (pool_token1_balance == 0 && wallet_token1_balance > 0) {
            console.log("Pool has no BRFI. Need to initialize with both tokens.");
            console.log("This might require swapping or direct transfer first.");
            
            // Try a safer range that might work with current pool state
            uint128 liquidity_amount = 1000000000000000; // 1e15
            
            // Try medium range first
            console.log("Trying medium range: -10000 to 10000");
            
            IMercuriusPool pool = IMercuriusPool(poolAddr);
            
            try pool.mint(msg.sender, -10000, 10000, liquidity_amount) returns (uint256 amt0, uint256 amt1) {
                console.log("Medium range result - Token0:", amt0, "Token1:", amt1);
                
                if (amt0 > 0 && amt1 > 0) {
                    // Both tokens needed - perfect for rebalancing
                    IERC20(token0).approve(poolAddr, amt0 * 2);
                    IERC20(token1).approve(poolAddr, amt1 * 2);
                    IERC20(token0).transfer(poolAddr, amt0);
                    IERC20(token1).transfer(poolAddr, amt1);
                    console.log("SUCCESS: Added balanced liquidity with medium range");
                } else if (amt1 > 0) {
                    // Only BRFI needed - good for rebalancing
                    IERC20(token1).approve(poolAddr, amt1 * 2);
                    IERC20(token1).transfer(poolAddr, amt1);
                    console.log("SUCCESS: Added BRFI liquidity (rebalancing)");
                } else {
                    console.log("Medium range only needs Kaju, trying narrow range...");
                    
                    // Try narrow range
                    try pool.mint(msg.sender, -1000, 1000, liquidity_amount) returns (uint256 amt0_narrow, uint256 amt1_narrow) {
                        console.log("Narrow range result - Token0:", amt0_narrow, "Token1:", amt1_narrow);
                        
                        if (amt0_narrow > 0 && amt1_narrow > 0) {
                            IERC20(token0).approve(poolAddr, amt0_narrow * 2);
                            IERC20(token1).approve(poolAddr, amt1_narrow * 2);
                            IERC20(token0).transfer(poolAddr, amt0_narrow);
                            IERC20(token1).transfer(poolAddr, amt1_narrow);
                            console.log("SUCCESS: Added balanced liquidity with narrow range");
                        } else {
                            console.log("All ranges failed. Using direct transfer method...");
                            
                            // Direct transfer approach
                            uint256 directAmount = 1000000000000000000; // 1 BRFI
                            IERC20(token1).transfer(poolAddr, directAmount);
                            console.log("SUCCESS: Direct transfer of 1 BRFI to pool");
                        }
                    } catch {
                        console.log("Narrow range failed, using direct transfer...");
                        uint256 directAmount = 1000000000000000000; // 1 BRFI
                        IERC20(token1).transfer(poolAddr, directAmount);
                        console.log("SUCCESS: Direct transfer of 1 BRFI to pool");
                    }
                }
            } catch {
                console.log("Medium range failed, trying direct transfer...");
                uint256 directAmount = 1000000000000000000; // 1 BRFI
                IERC20(token1).transfer(poolAddr, directAmount);
                console.log("SUCCESS: Direct transfer of 1 BRFI to pool");
            }
        } else {
            console.log("Pool already has both tokens or wallet missing BRFI");
        }
        
        vm.stopBroadcast();
    }
}

// Alternative: Direct token transfer script
contract DirectTransfer is Script {
    function run() external {
        address poolAddr = 0xd0335A436A34278fe380C5997152DB21F1DA7A10;
        address token1 = 0xE6DC9225E4C76f9c0b002Ab2782F687e35cc7666; // BRFI
        uint256 amount = 1000000000000000000; // 1e18 BRFI
        
        vm.startBroadcast();
        
        console.log("=== DIRECT BRFI TRANSFER TO POOL ===");
        console.log("Transferring", amount, "BRFI directly to pool");
        
        // Check balance first
        uint256 balance = IERC20(token1).balanceOf(msg.sender);
        console.log("Your BRFI balance:", balance);
        
        require(balance >= amount, "Insufficient BRFI balance");
        
        // Direct transfer to pool
        IERC20(token1).transfer(poolAddr, amount);
        
        console.log("SUCCESS: Transferred", amount, "BRFI to pool");
        console.log("Pool should now have some BRFI balance");
        
        vm.stopBroadcast();
    }
}