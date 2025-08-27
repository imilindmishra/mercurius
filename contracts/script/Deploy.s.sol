// script/Deploy.s.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {MercuriusFactory} from "../src/MercuriusFactory.sol";
import {Router} from "../src/Router.sol";
import {NonfungiblePositionManager} from "../src/NonfungiblePositionManager.sol";
import {KAJUCOIN} from "../src/KAJUCOIN.sol"; // NEW: Import KAJUCOIN
import {BRFICOIN} from "../src/BRFICOIN.sol"; // NEW: Import BRFICOIN
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Deploy is Script {
    function run()
        external
        returns (
            address factoryAddr,
            address routerAddr,
            address positionManagerAddr,
            address poolAddr,
            address kajuAddr,
            address brfiAddr
        )
    {
        vm.startBroadcast();

        address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));

        // --- Step 1: Deploy Your Two Mock Tokens ---
        KAJUCOIN kaju = new KAJUCOIN(deployer);
        kajuAddr = address(kaju);

        BRFICOIN brfi = new BRFICOIN(deployer);
        brfiAddr = address(brfi);

        // --- Step 2: Mint Initial Supply to Your Wallet ---
        uint256 mintAmount = 1_000_000 ether; // 1 Million of each token
        kaju.mint(deployer, mintAmount);
        brfi.mint(deployer, mintAmount);

        // --- Step 3: Deploy DEX Contracts ---
        MercuriusFactory factory = new MercuriusFactory();
        factoryAddr = address(factory);
        // The Router needs a placeholder WETH address; we'll use KAJUCOIN's
        Router router = new Router(factoryAddr, kajuAddr);
        routerAddr = address(router);
        NonfungiblePositionManager positionManager = new NonfungiblePositionManager(
            factoryAddr
        );
        positionManagerAddr = address(positionManager);

        // --- Step 4: Create the KAJU/BRFI Pool ---
        int24 startTick = 0; // Start with a 1:1 price
        poolAddr = factory.createPool(kajuAddr, brfiAddr, 3000, startTick);
        
        // --- Step 5: Add Initial Liquidity ---
        uint256 liquidityAmount = 100_000 ether; // 100,000 of each token

        IERC20(kaju).approve(positionManagerAddr, liquidityAmount);
        IERC20(brfi).approve(positionManagerAddr, liquidityAmount);

        address token0 = kajuAddr < brfiAddr ? kajuAddr : brfiAddr;
        address token1 = kajuAddr < brfiAddr ? brfiAddr : kajuAddr;

        NonfungiblePositionManager.MintParams memory params = NonfungiblePositionManager
            .MintParams({
                token0: token0,
                token1: token1,
                fee: 3000,
                tickLower: startTick - 100,
                tickUpper: startTick + 100,
                amount0Desired: liquidityAmount,
                amount1Desired: liquidityAmount,
                amount0Min: 0,
                amount1Min: 0,
                recipient: deployer,
                deadline: block.timestamp + 60
            });

        positionManager.mint(params);

        vm.stopBroadcast();
    }
}