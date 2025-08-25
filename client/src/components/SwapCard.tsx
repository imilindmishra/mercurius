// client/src/components/SwapCard.tsx

'use client';

import React, { useState } from 'react';
import { useAccount, useBalance, useNetwork, useContractWrite } from 'wagmi';
import { ConnectKitButton } from 'connectkit';
import { parseUnits } from 'viem';

// Import your token definitions and the TokenSelector component
import { Token, TOKENS, WETH_TOKEN } from '@/utils/tokens';
import { TokenSelector } from './TokenSelector';

// --- Router Details (from your project summary) ---
const ROUTER_ADDRESS = '0xa64eeFfBB70CA90765281245f62c974aFb0610B2';
const ROUTER_ABI = [{"inputs": [{"components": [{"name": "tokenIn", "type": "address"}, {"name": "tokenOut", "type": "address"}, {"name": "fee", "type": "uint24"}, {"name": "recipient", "type": "address"}, {"name": "amountIn", "type": "uint256"}, {"name": "sqrtPriceLimitX96", "type": "uint160"}], "name": "params", "type": "tuple"}], "name": "swapExactInputSingle", "outputs": [{"name": "amountOut", "type": "uint256"}], "stateMutability": "nonpayable", "type": "function"}];

export function SwapCard() {
  const { address, isConnected } = useAccount();
  const { chain } = useNetwork();

  // --- State Management ---
  const [inputAmount, setInputAmount] = useState('');
  const [inputToken, setInputToken] = useState<Token>(WETH_TOKEN);
  const [outputToken, setOutputToken] = useState<Token | null>(null);
  const [activeSelector, setActiveSelector] = useState<'input' | 'output' | null>(null);

  // --- Balance Fetching ---
  const { data: inputBalanceData } = useBalance({ address, token: inputToken?.address, chainId: chain?.id });
  const { data: outputBalanceData } = useBalance({ address, token: outputToken?.address, chainId: chain?.id });
  const formattedInputBalance = inputBalanceData ? parseFloat(inputBalanceData.formatted).toFixed(4) : '0.0000';
  const formattedOutputBalance = outputBalanceData ? parseFloat(outputBalanceData.formatted).toFixed(4) : '0.0000';

  // --- Contract Write Hook for Swapping ---
  const { write: executeSwap, isLoading, isSuccess, isError, error } = useContractWrite({
    address: ROUTER_ADDRESS,
    abi: ROUTER_ABI,
    functionName: 'swapExactInputSingle',
  });

  // --- Swap Handler Function ---
  const handleSwap = () => {
    if (!inputToken || !outputToken || !inputAmount || !address || !executeSwap) {
        alert("Please connect wallet, select both tokens, and enter an amount.");
        return;
    }

    const amountInBigInt = parseUnits(inputAmount, inputToken.decimals);

    const params = {
      tokenIn: inputToken.address,
      tokenOut: outputToken.address,
      fee: 3000, // The 0.3% fee tier
      recipient: address,
      amountIn: amountInBigInt,
      sqrtPriceLimitX96: 0, // 0 for no price limit
    };

    executeSwap({ args: [params] });
  };

  const handleSelectToken = (token: Token) => {
    if (activeSelector === 'input') {
        if (outputToken && token.address === outputToken.address) {
            setOutputToken(inputToken); // Swap tokens if new input is same as current output
        }
        setInputToken(token);
    } else if (activeSelector === 'output') {
        if (inputToken && token.address === inputToken.address) {
            setInputToken(outputToken); // Swap tokens if new output is same as current input
        }
        setOutputToken(token);
    }
    setActiveSelector(null);
  };
  
  const switchTokens = () => {
    if (!inputToken || !outputToken) return;
    const tempInputToken = inputToken;
    setInputToken(outputToken);
    setOutputToken(tempInputToken);
  }

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
          <button className="text-gray-400 hover:text-white">
            <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
          </button>
        </div>

        <div className="bg-gray-800/50 rounded-xl p-4 mb-2">
          <div className="flex justify-between mb-1">
            <span className="text-sm text-gray-400">You pay</span>
            <span className="text-sm text-gray-400">Balance: {formattedInputBalance}</span>
          </div>
          <div className="flex items-center justify-between">
            <input
              type="number"
              placeholder="0"
              className="bg-transparent text-3xl font-mono text-white w-full focus:outline-none"
              value={inputAmount}
              onChange={(e) => setInputAmount(e.target.value)}
            />
            <button onClick={() => openModal('input')} className="bg-gray-700 hover:bg-gray-600 text-white font-bold py-2 px-4 rounded-full flex items-center min-w-[120px] justify-between">
              <img src={inputToken.logoURI} alt={inputToken.name} className="w-6 h-6 rounded-full mr-2" />
              {inputToken.symbol}
              <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5 ml-1" viewBox="0 0 20 20" fill="currentColor"><path fillRule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clipRule="evenodd" /></svg>
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
                  <img src={outputToken.logoURI} alt={outputToken.name} className="w-6 h-6 rounded-full mr-2" />
                  {outputToken.symbol}
                </>
              ) : 'Select Token'}
              <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5 ml-1" viewBox="0 0 20 20" fill="currentColor"><path fillRule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clipRule="evenodd" /></svg>
            </button>
          </div>
        </div>

        <div className="mt-4">
          {isConnected ? (
            <button
              onClick={handleSwap}
              disabled={isLoading || !inputAmount || !outputToken}
              className="bg-blue-600 hover:bg-blue-700 text-white font-bold py-3 px-4 rounded-xl w-full text-lg disabled:bg-gray-600/50 disabled:cursor-not-allowed"
            >
              {isLoading ? 'Swapping...' : 'Swap'}
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
          {isError && <p className="text-red-400 mt-2 text-center">Error: {error?.message}</p>}
        </div>
      </div>
    </>
  );
}