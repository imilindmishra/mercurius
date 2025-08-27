'use client';

import React, { useState, useEffect, useMemo } from 'react';
import Image from 'next/image';
import { useAccount, useBalance, useWriteContract, useReadContract, useSimulateContract, useWaitForTransactionReceipt } from 'wagmi';
import { parseUnits, formatUnits, maxUint256 } from 'viem';
import { ConnectKitButton } from 'connectkit';
import { KAJU_TOKEN, Token, TOKENS } from '@/utils/tokens';
import { TokenSelector } from './TokenSelector';

// IMPORTANT: Update this with the new address from your redeployment
const ROUTER_ADDRESS = '0x24cf4c5357481BeA6ABF3761a6BDBFbe1840746d';
const FACTORY_ADDRESS = '0x7c8dA50Ec2B98EcD536BfdF2C33D09302455dc2e';

// Constants for sqrt price limits (from Uniswap V3 specs)
const MIN_SQRT_RATIO = BigInt('4295128739');
const MAX_SQRT_RATIO = BigInt('1461446703485210103287273052203988822375603979126');

const ROUTER_ABI = [
  {
    inputs: [
      {
        components: [
          { name: 'tokenIn', type: 'address' },
          { name: 'tokenOut', type: 'address' },
          { name: 'fee', type: 'uint24' },
          { name: 'recipient', type: 'address' },
          { name: 'amountIn', type: 'uint256' },
          { name: 'sqrtPriceLimitX96', type: 'uint160' }
        ],
        name: 'params',
        type: 'tuple'
      }
    ],
    name: 'swapExactInputSingle',
    outputs: [{ name: 'amountOut', type: 'uint256' }],
    stateMutability: 'payable',
    type: 'function'
  }
];

const FACTORY_ABI = [
  {
    inputs: [
      { name: 'token0', type: 'address' },
      { name: 'token1', type: 'address' },
      { name: 'fee', type: 'uint24' }
    ],
    name: 'getPool',
    outputs: [{ name: 'pool', type: 'address' }],
    stateMutability: 'view',
    type: 'function'
  }
];

const POOL_ABI = [
  {
    inputs: [],
    name: 'liquidity',
    outputs: [{ name: '', type: 'uint128' }],
    stateMutability: 'view',
    type: 'function'
  },
  {
    inputs: [],
    name: 'slot0',
    outputs: [
      { name: 'sqrtPriceX96', type: 'uint160' },
      { name: 'tick', type: 'int24' }
    ],
    stateMutability: 'view',
    type: 'function'
  }
];

const ERC20_ABI = [
  {
    inputs: [
      { name: 'owner', type: 'address' },
      { name: 'spender', type: 'address' }
    ],
    name: 'allowance',
    outputs: [{ name: '', type: 'uint256' }],
    stateMutability: 'view',
    type: 'function'
  },
  {
    inputs: [
      { name: 'spender', type: 'address' },
      { name: 'amount', type: 'uint256' }
    ],
    name: 'approve',
    outputs: [{ name: '', type: 'bool' }],
    stateMutability: 'nonpayable',
    type: 'function'
  }
];

export function SwapCard() {
  const { address, isConnected, chain } = useAccount();

  const [inputAmount, setInputAmount] = useState('');
  const [inputToken, setInputToken] = useState<Token>(KAJU_TOKEN);
  const [outputToken, setOutputToken] = useState<Token | null>(null);
  const [activeSelector, setActiveSelector] = useState<'input' | 'output' | null>(null);

  const amountToSwap = inputAmount ? parseUnits(inputAmount, inputToken.decimals) : BigInt(0);

  // Sort tokens for pool lookup (token0 < token1)
  const [token0, token1] = inputToken && outputToken 
    ? inputToken.address.toLowerCase() < outputToken.address.toLowerCase()
      ? [inputToken.address, outputToken.address]
      : [outputToken.address, inputToken.address]
    : [null, null];

  // Compute swap direction and price limit
  const zeroForOne = inputToken && outputToken ? inputToken.address.toLowerCase() < outputToken.address.toLowerCase() : false;
  const sqrtPriceLimitX96 = zeroForOne ? (MIN_SQRT_RATIO + BigInt(1)) : (MAX_SQRT_RATIO - BigInt(1));

  // --- CHECK IF POOL EXISTS ---
  const { data: poolAddressRaw } = useReadContract({
    address: FACTORY_ADDRESS,
    abi: FACTORY_ABI,
    functionName: 'getPool',
    args: token0 && token1 ? [token0, token1, 3000] : undefined,
    query: { enabled: !!token0 && !!token1 }
  });

  // Normalize pool address immediately so subsequent hooks can use it
  const poolAddress = typeof poolAddressRaw === 'string' ? (poolAddressRaw as `0x${string}`) : undefined;

  // --- CHECK POOL LIQUIDITY ---
  const { data: poolLiquidityRaw } = useReadContract({
    address: poolAddress as (`0x${string}` | undefined),
    abi: POOL_ABI,
    functionName: 'liquidity',
    query: { enabled: !!poolAddress && poolAddress !== '0x0000000000000000000000000000000000000000' }
  });

  // --- CHECK POOL SLOT0 (PRICE INFO) ---
  const { data: poolSlot0Raw } = useReadContract({
    address: poolAddress as (`0x${string}` | undefined),
    abi: POOL_ABI,
    functionName: 'slot0',
    query: { enabled: !!poolAddress && poolAddress !== '0x0000000000000000000000000000000000000000' }
  });

  // Normalize raw contract return values into well-typed local variables using useMemo
  const poolLiquidity = useMemo(() => {
    if (poolLiquidityRaw == null) return BigInt(0);
    try {
      return typeof poolLiquidityRaw === 'bigint' ? poolLiquidityRaw : BigInt(String(poolLiquidityRaw));
    } catch {
      return BigInt(0);
    }
  }, [poolLiquidityRaw]);

  const poolSlot0 = useMemo(() => {
    if (poolSlot0Raw == null || !Array.isArray(poolSlot0Raw) || poolSlot0Raw.length < 2) return undefined;
    try {
      return {
        sqrtPriceX96: typeof poolSlot0Raw[0] === 'bigint' ? poolSlot0Raw[0] : BigInt(String(poolSlot0Raw[0])),
        tick: Number(poolSlot0Raw[1])
      };
    } catch {
      return undefined;
    }
  }, [poolSlot0Raw]);

  // Memoize debug info to prevent unnecessary re-renders
  const debugInfo = useMemo(() => ({
    inputToken: inputToken?.symbol,
    outputToken: outputToken?.symbol,
    token0,
    token1,
    poolAddress,
    poolLiquidity: poolLiquidity.toString(),
    poolSlot0: poolSlot0 ? { 
      sqrtPriceX96: poolSlot0.sqrtPriceX96.toString(), 
      tick: poolSlot0.tick.toString() 
    } : 'N/A',
    amountToSwap: amountToSwap.toString()
  }), [inputToken?.symbol, outputToken?.symbol, token0, token1, poolAddress, poolLiquidity, poolSlot0, amountToSwap]);

  // --- HOOKS for ALLOWANCE ---
  const { data: allowanceRaw, refetch: refetchAllowance } = useReadContract({
    address: inputToken?.address,
    abi: ERC20_ABI,
    functionName: 'allowance',
    args: [address, ROUTER_ADDRESS],
    chainId: chain?.id,
    query: { enabled: !!address && !!inputToken }
  });

  // Normalize allowanceRaw into a bigint
  const allowance = useMemo(() => {
    if (allowanceRaw == null) return BigInt(0);
    try {
      return typeof allowanceRaw === 'bigint' ? allowanceRaw : BigInt(String(allowanceRaw));
    } catch {
      return BigInt(0);
    }
  }, [allowanceRaw]);

  // --- HOOKS for APPROVE and SWAP ---
  const { 
    writeContract: executeApprove, 
    data: approveHash, 
    isPending: isApproving, 
    error: approveError 
  } = useWriteContract();
  
  const { 
    writeContract: executeSwap, 
    data: swapHash, 
    isPending: isSwapping, 
    error: swapError 
  } = useWriteContract();

  // --- HOOK to get SWAP QUOTE ---
  const { data: quoteData, error: quoteError } = useSimulateContract({
    address: ROUTER_ADDRESS,
    abi: ROUTER_ABI,
    functionName: 'swapExactInputSingle',
    args: outputToken && amountToSwap > BigInt(0) ? [
      {
        tokenIn: inputToken.address,
        tokenOut: outputToken.address,
        fee: 3000,
        recipient: address!,
        amountIn: amountToSwap,
        sqrtPriceLimitX96
      }
    ] : undefined,
    query: {
      enabled: !!inputToken && 
               !!outputToken && 
               !!address && 
               amountToSwap > BigInt(0) && 
               !!poolAddress && 
               poolAddress !== '0x0000000000000000000000000000000000000000' &&
               poolLiquidity > BigInt(0)
    }
  });

  const quoteAmountOut = quoteData?.result && outputToken 
    ? formatUnits(quoteData.result as bigint, outputToken.decimals) 
    : '';

  // --- HOOK to wait for APPROVE transaction ---
  const { isSuccess: isApproveSuccess, isLoading: isApproveConfirming } = useWaitForTransactionReceipt({ 
    hash: approveHash 
  });

  // Refetch allowance after approval is confirmed
  useEffect(() => {
    if (isApproveSuccess) {
      refetchAllowance();
    }
  }, [isApproveSuccess, refetchAllowance]);

  // --- HOOK to wait for SWAP transaction ---
  const { isSuccess: isSwapSuccess, isLoading: isSwapConfirming } = useWaitForTransactionReceipt({ 
    hash: swapHash 
  });

  // --- BALANCE HOOK ---
  const { data: inputBalanceData } = useBalance({
    address,
    token: inputToken?.address,
    chainId: chain?.id
  });

  const formattedInputBalance = inputBalanceData 
    ? parseFloat(formatUnits(inputBalanceData.value, inputBalanceData.decimals)).toFixed(4) 
    : '0.0000';

  // --- COMPUTED VALUES ---
  const needsApproval = amountToSwap > BigInt(0) && allowance < amountToSwap;
  const canSwap = !needsApproval && !!quoteData && !quoteError && amountToSwap > 0 && !!outputToken;

  // --- HANDLERS ---
  const handleApprove = () => {
    executeApprove({
      address: inputToken.address,
      abi: ERC20_ABI,
      functionName: 'approve',
      args: [ROUTER_ADDRESS, maxUint256]
    });
  };

  const handleSwap = () => {
    if (!outputToken || !address) return;
    
    executeSwap({
      address: ROUTER_ADDRESS,
      abi: ROUTER_ABI,
      functionName: 'swapExactInputSingle',
      args: [
        {
          tokenIn: inputToken.address,
          tokenOut: outputToken.address,
          fee: 3000,
          recipient: address,
          amountIn: amountToSwap,
          sqrtPriceLimitX96
        }
      ]
    });
  };

  const handleSelectToken = (token: Token) => {
    if (activeSelector === 'input') {
      setInputToken(token);
    } else if (activeSelector === 'output') {
      setOutputToken(token);
    }
    setActiveSelector(null);
  };

  const switchTokens = () => {
    if (!inputToken || !outputToken) return;
    const temp = inputToken;
    setInputToken(outputToken);
    setOutputToken(temp);
  };

  const openModal = (selector: 'input' | 'output') => {
    setActiveSelector(selector);
  };

  const setMaxAmount = () => {
    if (inputBalanceData) {
      setInputAmount(formatUnits(inputBalanceData.value, inputBalanceData.decimals));
    }
  };

  // --- RENDER BUTTON LOGIC ---
  const renderButton = () => {
    if (!isConnected) {
      return (
        <ConnectKitButton.Custom>
          {({ show }) => (
            <button 
              onClick={show} 
              className="bg-blue-600 hover:bg-blue-700 w-full font-bold py-3 px-4 rounded-xl text-lg transition-colors"
            >
              Connect Wallet
            </button>
          )}
        </ConnectKitButton.Custom>
      );
    }

    if (!outputToken) {
      return (
        <button 
          disabled 
          className="bg-gray-600 w-full font-bold py-3 px-4 rounded-xl text-lg opacity-50 cursor-not-allowed"
        >
          Select Output Token
        </button>
      );
    }

    if (!inputAmount || amountToSwap === BigInt(0)) {
      return (
        <button 
          disabled 
          className="bg-gray-600 w-full font-bold py-3 px-4 rounded-xl text-lg opacity-50 cursor-not-allowed"
        >
          Enter Amount
        </button>
      );
    }

    if (needsApproval) {
      return (
        <button
          onClick={handleApprove}
          disabled={isApproving || isApproveConfirming}
          className="bg-yellow-600 hover:bg-yellow-700 w-full font-bold py-3 px-4 rounded-xl text-lg disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
        >
          {isApproving ? 'Approving...' : isApproveConfirming ? 'Confirming...' : `Approve ${inputToken.symbol}`}
        </button>
      );
    }

    return (
      <button
        onClick={handleSwap}
        disabled={isSwapping || isSwapConfirming || !canSwap}
        className="bg-blue-600 hover:bg-blue-700 w-full font-bold py-3 px-4 rounded-xl text-lg disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
      >
        {isSwapping ? 'Swapping...' : isSwapConfirming ? 'Confirming...' : 'Swap'}
      </button>
    );
  };

  return (
    <>
      <TokenSelector
        isOpen={activeSelector !== null}
        onClose={() => setActiveSelector(null)}
        onSelectToken={handleSelectToken}
        tokens={TOKENS}
      />
      
      <div className="bg-gray-900/50 backdrop-blur-sm border border-gray-700/50 rounded-2xl p-4 sm:p-6 w-full max-w-md mx-auto">
        {/* Header */}
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-xl font-bold text-white">Swap</h2>
        </div>

        {/* DEBUG INFO */}
        <details className="mb-4 p-3 bg-gray-800 rounded-lg">
          <summary className="cursor-pointer text-yellow-400 font-medium">Debug Info</summary>
          <pre className="text-xs text-gray-300 mt-2 overflow-auto">
            {JSON.stringify(debugInfo, null, 2)}
          </pre>
          <div className="mt-2 text-sm">
            <p className="text-gray-300">Pool Address: <span className="text-blue-400">{poolAddress || 'Not found'}</span></p>
            <p className="text-gray-300">Pool Liquidity: <span className="text-green-400">{poolLiquidity.toString()}</span></p>
            <p className="text-gray-300">Quote Error: <span className="text-red-400">{quoteError?.message || 'None'}</span></p>
          </div>
        </details>

        {/* Input Section */}
        <div className="bg-gray-800/50 rounded-xl p-4 mb-2">
          <div className="flex justify-between mb-2 text-sm text-gray-400">
            <span>You pay</span>
            <span className="flex items-center gap-2">
              Balance: {formattedInputBalance}
              <button
                onClick={setMaxAmount}
                className="text-blue-400 hover:text-blue-300 text-xs font-medium"
              >
                MAX
              </button>
            </span>
          </div>
          <div className="flex items-center justify-between">
            <input
              type="number"
              placeholder="0"
              className="bg-transparent text-3xl font-mono w-full focus:outline-none text-white placeholder-gray-500"
              value={inputAmount}
              onChange={(e) => setInputAmount(e.target.value)}
            />
            <button
              onClick={() => openModal('input')}
              className="bg-gray-700 hover:bg-gray-600 font-bold py-2 px-4 rounded-full flex items-center min-w-[120px] justify-between transition-colors"
            >
              <Image
                src={inputToken.logoURI}
                alt={inputToken.name}
                className="w-6 h-6 rounded-full"
                width={24}
                height={24}
              />
              <span className="text-white">{inputToken.symbol}</span>
            </button>
          </div>
        </div>

        {/* Switch Button */}
        <div className="flex justify-center my-[-10px] z-10 relative">
          <button
            onClick={switchTokens}
            disabled={!outputToken}
            className="bg-gray-700 border-4 border-gray-900 rounded-full p-2 text-gray-400 hover:text-white hover:bg-gray-600 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              className="h-5 w-5"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="2"
                d="M19 14l-7 7m0 0l-7-7m7 7V3"
              />
            </svg>
          </button>
        </div>

        {/* Output Section */}
        <div className="bg-gray-800/50 rounded-xl p-4 mt-2">
          <div className="flex justify-between mb-2 text-sm text-gray-400">
            <span>You receive</span>
          </div>
          <div className="flex items-center justify-between">
            <input
              type="number"
              placeholder="0"
              className="bg-transparent text-3xl font-mono w-full focus:outline-none text-white placeholder-gray-500"
              readOnly
              value={quoteAmountOut}
            />
            <button
              onClick={() => openModal('output')}
              className="bg-gray-700 hover:bg-gray-600 font-bold py-2 px-4 rounded-full flex items-center min-w-[120px] justify-between transition-colors"
            >
              {outputToken ? (
                <>
                  <Image
                    src={outputToken.logoURI}
                    alt={outputToken.name}
                    className="w-6 h-6 rounded-full"
                    width={24}
                    height={24}
                  />
                  <span className="text-white">{outputToken.symbol}</span>
                </>
              ) : (
                <span className="text-gray-300">Select Token</span>
              )}
            </button>
          </div>
        </div>

        {/* Pool Status Messages */}
        {outputToken && poolAddress === '0x0000000000000000000000000000000000000000' && (
          <div className="mt-2 p-2 bg-orange-900/20 border border-orange-500/20 rounded-lg">
            <p className="text-orange-400 text-sm">
              ⚠️ Pool doesn&apos;t exist for this token pair. You need to create liquidity first.
            </p>
          </div>
        )}

        {outputToken && poolAddress && poolAddress !== '0x0000000000000000000000000000000000000000' && poolLiquidity === BigInt(0) && (
          <div className="mt-2 p-2 bg-orange-900/20 border border-orange-500/20 rounded-lg">
            <p className="text-orange-400 text-sm">
              ⚠️ Pool exists but has no liquidity. Add liquidity to enable swaps.
            </p>
          </div>
        )}

        {/* Quote Error Display */}
        {quoteError && amountToSwap > 0 && outputToken && (
          <div className="mt-2 p-2 bg-red-900/20 border border-red-500/20 rounded-lg">
            <p className="text-red-400 text-sm">
              Unable to get price quote: {quoteError.message}
            </p>
          </div>
        )}

        {/* Action Button */}
        <div className="mt-4">
          {renderButton()}
        </div>

        {/* Status Messages */}
        {isSwapSuccess && (
          <div className="mt-3 p-3 bg-green-900/20 border border-green-500/20 rounded-lg">
            <p className="text-green-400 text-center font-medium">
              ✅ Swap Completed Successfully!
            </p>
          </div>
        )}

        {isApproveSuccess && needsApproval === false && !isSwapSuccess && (
          <div className="mt-3 p-3 bg-blue-900/20 border border-blue-500/20 rounded-lg">
            <p className="text-blue-400 text-center font-medium">
              ✅ Approval Confirmed! You can now swap.
            </p>
          </div>
        )}

        {swapError && (
          <div className="mt-3 p-3 bg-red-900/20 border border-red-500/20 rounded-lg">
            <p className="text-red-400 text-sm">
              <strong>Swap Error:</strong> {swapError.message}
            </p>
          </div>
        )}

        {approveError && (
          <div className="mt-3 p-3 bg-red-900/20 border border-red-500/20 rounded-lg">
            <p className="text-red-400 text-sm">
              <strong>Approval Error:</strong> {approveError.message}
            </p>
          </div>
        )}
      </div>
    </>
  );
}