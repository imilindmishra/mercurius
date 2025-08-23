// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {TickMath} from "./libraries/TickMath.sol";
import {TickBitmap} from "./libraries/TickBitmap.sol";
import {Tick} from "./libraries/Tick.sol";
import {LiquidityMath} from "./libraries/LiquidityMath.sol";
import {SqrtPriceMath} from "./libraries/SqrtPriceMath.sol";
import {Position} from "./libraries/Position.sol";

contract MercuriusPool {
    using Position for Position.Info;
    address public immutable factory;
    address public immutable token0;
    address public immutable token1;
    uint24 public immutable fee;

    uint128 public liquidity;
    uint160 public sqrtPriceX96;
    int24 public tick;

    mapping(int24 => Tick.Info) public ticks;
    mapping(int16 => uint256) public tickBitmap;
    mapping(bytes32 => Position.Info) public positions;

    //calling it only once when the contract is deployed 
    constructor(address _token0, address _token1, uint24 _fee, uint160 _sqrtPriceX96) 
    {
        factory = msg.sender;
        token0 = _token0;
        token1 = _token1;
        fee = _fee;

        sqrtPriceX96 = _sqrtPriceX96; //setting the initial price
        tick = TickMath.getTickAtSqrtRatio(_sqrtPriceX96);
    } 

    // mint function
    function mint(address recipient, int24 tickLower, int24 tickUpper, uint128 amount)
    external returns ( uint256 amount0, uint256 amount1) {
        require(tickLower < tickUpper, "TLU");
        require(tickLower >= TickMath.MIN_TICK && tickUpper <= TickMath.MAX_TICK, "T");

        //updating the data for the lower and the upper ticks
        _updatePosition(recipient, tickLower, tickUpper, int128(amount));

        //If the current price is  within the new liquidity range, update the pool's liquidity
        if (tick >= tickLower  && tick < tickUpper) {
            liquidity = LiquidityMath.addDelta(liquidity, int128(amount));
        }

        uint160 sqrtRatioA = TickMath.MIN_SQRT_RATIO;
        uint160 sqrtRatioB = TickMath.MAX_SQRT_RATIO;

        amount0 = SqrtPriceMath.getAmount0Delta(sqrtPriceX96, sqrtRatioB, amount);
        amount1 = SqrtPriceMath.getAmount1Delta(sqrtRatioA, sqrtPriceX96, amount);
    }

    function swap(
        address recipient,
        bool zeroForOne,
        uint256 amountSpecified,
        uint160 sqrtPriceLimitX96
    ) external returns ( int256 amount0, int256 amount1 ) {
        uint160 sqrtRatioTargetX96;
        if (zeroForOne) {
            // swapping token0 for token1, price goes down
            require(sqrtPriceLimitX96 < sqrtPriceX96, "SL");
            sqrtRatioTargetX96 = sqrtPriceLimitX96;
        } else {
            // swapping token1 for token0, price goes up
            require(sqrtPriceLimitX96 > sqrtPriceX96, "SL");
            sqrtRatioTargetX96 = sqrtPriceLimitX96;
        }

        SwapMath.ComputeSwapStepResult memory step = SwapMath.computeSwapStep(
            sqrtPriceX96,
            sqrtRatioTargetX96,
            liquidity,
            amountSpecified,
            fee
        );

        // Update pool state
        sqrtPriceX96 = step.sqrtRatioNextX96;
        tick = TickMath.getTickAtSqrtRatio(step.sqrtRatioNextX96);

        if (zeroForOne) {
            amount0 = -int256(step.amountOut);
            amount1 = int256(step.amountIn);
        } else {
            amount0 = int256(step.amountIn);
            amount1 = -int256(step.amountOut);
        }
    
    }






    function _updatePosition(address recipient, int24 tickLower, int24 tickUpper, int128 liquidityDelta)
    private {
        bytes32 positionKey = keccak256(abi.encodePacked(recipient, tickLower, tickUpper));
        Position.Info storage position = positions[positionKey];
        position.update(liquidityDelta);

        //updating the lower tick
        _updateTick(tickLower, liquidityDelta);
        //update the upper tick
        _updateTick(tickUpper, liquidityDelta);
    }

    function _updateTick(int24 _tick, int128 liquidityDelta) 
    private {
        Tick.Info storage tickInfo = ticks[_tick];
        uint128 liquidityGrossBefore = tickInfo.liquidityGross;

        //update the gross liquidity for the tick
        uint128 liquidityGrossAfter = LiquidityMath.addDelta(
            liquidityGrossBefore,
            liquidityDelta
        );

        //if liquidity becomes 0, flip the bit in the bitmap to "inactive"
        if (liquidityGrossBefore == 0) {
            TickBitmap.flipTick(tickBitmap, _tick);
        }

        tickInfo.liquidityGross = liquidityGrossAfter;
    }


    
}