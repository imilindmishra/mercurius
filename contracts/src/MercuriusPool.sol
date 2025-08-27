// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TickMath} from "./libraries/TickMath.sol";
import {TickBitmap} from "./libraries/TickBitmap.sol";
import {Tick} from "./libraries/Tick.sol";
import {LiquidityMath} from "./libraries/LiquidityMath.sol";
import {SqrtPriceMath} from "./libraries/SqrtPriceMath.sol";
import {SwapMath} from "./libraries/SwapMath.sol";
import {Position} from "./libraries/Position.sol";
import {IMercuriusPool} from "./interfaces/IMercuriusPool.sol";
import {IMercuriusFactory} from "./interfaces/IMercuriusFactory.sol";

contract MercuriusPool is IMercuriusPool {
    using Tick for mapping(int24 => Tick.Info);
    using TickBitmap for mapping(int16 => uint256);
    using Position for mapping(bytes32 => Position.Info);

    address public immutable override factory;
    address public immutable override token0;
    address public immutable override token1;
    uint24 public immutable override fee;

    uint128 public override liquidity;
    Slot0 public override slot0;

    mapping(int24 => Tick.Info) public override ticks;
    mapping(int16 => uint256) public override tickBitmap;
    mapping(bytes32 => Position.Info) public override positions;

    struct SwapState {
        uint256 amountSpecifiedRemaining;
        uint256 amountCalculated;
        uint160 sqrtPriceX96;
        int24 tick;
        uint128 liquidity;
    }

    constructor() {
        (
            factory,
            token0,
            token1,
            fee,
            slot0.tick
        ) = IMercuriusFactory(msg.sender).parameters();
        slot0.sqrtPriceX96 = TickMath.getSqrtRatioAtTick(slot0.tick);
    }

    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external override returns (uint256 amount0, uint256 amount1) {
        require(
            tickLower < tickUpper &&
                tickLower >= TickMath.MIN_TICK &&
                tickUpper <= TickMath.MAX_TICK,
            "IT"
        );
        
        // This function's only job is to update ticks and liquidity.
        // The NonfungiblePositionManager handles the position mapping.
        ticks.update(tickLower, slot0.tick, amount, false);
        ticks.update(tickUpper, slot0.tick, amount, true);

        if (slot0.tick >= tickLower && slot0.tick < tickUpper) {
            liquidity = LiquidityMath.addDelta(liquidity, int128(amount));
        }

        (amount0, amount1) = _getAmountsForLiquidity(
            TickMath.getSqrtRatioAtTick(tickLower),
            TickMath.getSqrtRatioAtTick(tickUpper),
            amount
        );
    }

    function swap(
        address recipient,
        bool zeroForOne,
        uint256 amountSpecified,
        uint160 sqrtPriceLimitX96
    ) external override returns (int256 amount0, int256 amount1) {
        Slot0 memory _slot0 = slot0;
        require(
            zeroForOne
                ? sqrtPriceLimitX96 < _slot0.sqrtPriceX96 && sqrtPriceLimitX96 > TickMath.MIN_SQRT_RATIO
                : sqrtPriceLimitX96 > _slot0.sqrtPriceX96 && sqrtPriceLimitX96 < TickMath.MAX_SQRT_RATIO,
            "SPL"
        );
        SwapState memory state = SwapState({
            amountSpecifiedRemaining: amountSpecified,
            amountCalculated: 0,
            sqrtPriceX96: _slot0.sqrtPriceX96,
            tick: _slot0.tick,
            liquidity: liquidity
        });
        while (state.amountSpecifiedRemaining > 0) {
            (int24 nextTick, ) = tickBitmap.nextInitializedTickWithinOneWord(
                state.tick,
                1,
                zeroForOne
            );
            nextTick = nextTick < TickMath.MIN_TICK ? TickMath.MIN_TICK : nextTick;
            nextTick = nextTick > TickMath.MAX_TICK ? TickMath.MAX_TICK : nextTick;
            uint160 sqrtRatioTargetX96 = TickMath.getSqrtRatioAtTick(nextTick);
            if (zeroForOne) {
                if (sqrtRatioTargetX96 < sqrtPriceLimitX96) sqrtRatioTargetX96 = sqrtPriceLimitX96;
            } else {
                if (sqrtRatioTargetX96 > sqrtPriceLimitX96) sqrtRatioTargetX96 = sqrtPriceLimitX96;
            }
            SwapMath.ComputeSwapStepResult memory step = SwapMath.computeSwapStep(
                state.sqrtPriceX96,
                sqrtRatioTargetX96,
                state.liquidity,
                state.amountSpecifiedRemaining,
                fee
            );
            state.sqrtPriceX96 = step.sqrtRatioNextX96;
            state.amountSpecifiedRemaining -= (step.amountIn + step.feeAmount);
            state.amountCalculated += step.amountOut;
            if (state.sqrtPriceX96 == sqrtRatioTargetX96) {
                int128 liquidityDelta = ticks.cross(nextTick, state.tick > nextTick);
                state.liquidity = LiquidityMath.addDelta(state.liquidity, liquidityDelta);
                state.tick = zeroForOne ? nextTick - 1 : nextTick;
            } else {
                state.tick = TickMath.getTickAtSqrtRatio(state.sqrtPriceX96);
            }
        }
        if (zeroForOne) {
            amount0 = -int256(amountSpecified);
            amount1 = int256(state.amountCalculated);
        } else {
            amount0 = int256(state.amountCalculated);
            amount1 = -int256(amountSpecified);
        }
        slot0.tick = state.tick;
        slot0.sqrtPriceX96 = state.sqrtPriceX96;
        liquidity = state.liquidity;

        if (zeroForOne) {
            IERC20(token1).transfer(recipient, uint256(amount1));
        } else {
            IERC20(token0).transfer(recipient, uint256(amount0));
        }
    }

    function _getAmountsForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 _liquidity
    ) private pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) {
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        }
        amount0 = SqrtPriceMath.getAmount0Delta(sqrtRatioAX96, sqrtRatioBX96, _liquidity);
        amount1 = SqrtPriceMath.getAmount1Delta(sqrtRatioAX96, sqrtRatioBX96, _liquidity);
    }
}