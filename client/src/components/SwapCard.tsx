'use client';

import React, { useState, useEffect } from 'react'; 
import Image from 'next/image'; 
import { useAccount, useBalance, useWriteContract } from 'wagmi';
import { ConnectKitButton } from 'connectkit';
import { parseUnits } from 'viem';

import { Token, TOKENS, WETH_TOKEN } from '@/utils/tokens';
import { TokenSelector } from './TokenSelector';

// CORRECTED: Updated with your new router address
const ROUTER_ADDRESS = '0xE6DC9225E4C76f9c0b002Ab2782F687e35cc7666'; 
const ROUTER_ABI = [{"inputs":[{"components":[{"name":"tokenIn","type":"address"},{"name":"tokenOut","type":"address"},{"name":"fee","type":"uint24"},{"name":"recipient","type":"address"},{"name":"amountIn","type":"uint256"},{"name":"sqrtPriceLimitX96","type":"uint160"}],"name":"params","type":"tuple"}],"name":"swapExactInputSingle","outputs":[{"name":"amountOut","type":"uint256"}],"stateMutability":"payable","type":"function"}];

export function SwapCard() {
  const { address, isConnected, chain } = useAccount();

  const [inputAmount, setInputAmount] = useState('');
  const [inputToken, setInputToken] = useState<Token>(WETH_TOKEN);
  const [outputToken, setOutputToken] = useState<Token | null>(null);
  const [activeSelector, setActiveSelector] = useState<'input' | 'output' | null>(null);

  const { data: inputBalanceData } = useBalance({ 
    address, 
    token: inputToken?.symbol === 'ETH' ? undefined : inputToken?.address, 
    chainId: chain?.id 
  });
  const formattedInputBalance = inputBalanceData ? parseFloat(inputBalanceData.formatted).toFixed(4) : '0.0000';

  const { data: outputBalanceData } = useBalance({
    address,
    token: outputToken?.symbol === 'ETH' ? undefined : outputToken?.address,
    chainId: chain?.id
  });
  const formattedOutputBalance = outputBalanceData ? parseFloat(outputBalanceData.formatted).toFixed(4) : '0.0000';
  
  const { writeContract: executeSwap, isPending, isSuccess, error } = useWriteContract();

  const handleSwap = () => {
    if (!inputToken || !outputToken || !inputAmount || !address) return;
    
    const isNativeEthSwap = inputToken.symbol === 'ETH';
    const amountInBigInt = parseUnits(inputAmount, inputToken.decimals);

    executeSwap({
      address: ROUTER_ADDRESS,
      abi: ROUTER_ABI,
      functionName: 'swapExactInputSingle',
      value: isNativeEthSwap ? amountInBigInt : BigInt(0),
      args: [{
        tokenIn: isNativeEthSwap ? WETH_TOKEN.address : inputToken.address,
        tokenOut: outputToken.address,
        fee: 3000,
        recipient: address,
        amountIn: amountInBigInt,
        sqrtPriceLimitX96: 0,
      }]
    });
  };

  const handleSelectToken = (token: Token) => {
    if (activeSelector === 'input') {
      setInputToken(token);
    } else {
      setOutputToken(token);
    }
    setActiveSelector(null);
  };
  
  const switchTokens = () => {
    if (!inputToken || !outputToken) return;
    setInputToken(outputToken);
    setOutputToken(inputToken);
  };

  const openModal = (selector: 'input' | 'output') => setActiveSelector(selector);
  return (
    <>
      <TokenSelector
        isOpen={activeSelector !== null}
        onClose={() => setActiveSelector(null)}
        onSelectToken={handleSelectToken}
        tokens={TOKENS}
      />
      <div className="bg-gray-900/50 backdrop-blur-sm border border-gray-700/50 rounded-2xl p-4 sm:p-6 w-full max-w-md mx-auto">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-xl font-bold text-white">Swap</h2>
        </div>
        <div className="bg-gray-800/50 rounded-xl p-4 mb-2">
          <div className="flex justify-between mb-1">
            <span className="text-sm text-gray-400">You pay</span>
            <span className="text-sm text-gray-400">Balance: {formattedInputBalance}</span>
          </div>
          <div className="flex items-center justify-between">
            <input type="number" placeholder="0" className="bg-transparent text-3xl font-mono text-white w-full focus:outline-none" value={inputAmount} onChange={(e) => setInputAmount(e.target.value)} />
            <button onClick={() => openModal('input')} className="bg-gray-700 hover:bg-gray-600 text-white font-bold py-2 px-4 rounded-full flex items-center min-w-[120px] justify-between">
              <Image src={inputToken.logoURI} alt={inputToken.name} className="w-6 h-6 rounded-full mr-2" width={24} height={24} />
              {inputToken.symbol}
            </button>
          </div>
        </div>
        <div className="flex justify-center my-[-10px] z-10 relative">
          <button onClick={switchTokens} className="bg-gray-700 border-4 border-gray-900 rounded-full p-2 text-gray-400 hover:text-white hover:bg-gray-600 transition-transform duration-200 hover:rotate-180">
            <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 14l-7 7m0 0l-7-7m7 7V3" /></svg>
          </button>
        </div>
        <div className="bg-gray-800/50 rounded-xl p-4 mt-2">
          <div className="flex justify-between mb-1">
            <span className="text-sm text-gray-400">You receive</span>
            <span className="text-sm text-gray-400">Balance: {formattedOutputBalance}</span>
          </div>
          <div className="flex items-center justify-between">
            <input type="number" placeholder="0" className="bg-transparent text-3xl font-mono text-white w-full focus:outline-none" readOnly />
            <button onClick={() => openModal('output')} className="bg-gray-700 hover:bg-gray-600 text-white font-bold py-2 px-4 rounded-full flex items-center min-w-[120px] justify-between">
              {outputToken ? (
                <>
                  <Image src={outputToken.logoURI} alt={outputToken.name} className="w-6 h-6 rounded-full mr-2" width={24} height={24} />
                  {outputToken.symbol}
                </>
              ) : 'Select Token'}
            </button>
          </div>
        </div>
        <div className="mt-4">
          {isConnected ? (
            <button onClick={handleSwap} disabled={isPending || !inputAmount || !outputToken} className="bg-blue-600 hover:bg-blue-700 text-white font-bold py-3 px-4 rounded-xl w-full text-lg disabled:bg-gray-600/50 disabled:cursor-not-allowed">
              {isPending ? 'Swapping...' : 'Swap'}
            </button>
          ) : (
            <ConnectKitButton.Custom>
              {({ show }) => (
                <button onClick={show} className="bg-blue-600 hover:bg-blue-700 text-white font-bold py-3 px-4 rounded-xl w-full text-lg">
                  Connect Wallet
                </button>
              )}
            </ConnectKitButton.Custom>
          )}
          {isSuccess && <p className="text-green-400 mt-2 text-center">Swap Successful!</p>}
          {error && <p className="text-red-400 mt-2 text-center">Error: {error?.message}</p>}
        </div>
      </div>
    </>
  );
}