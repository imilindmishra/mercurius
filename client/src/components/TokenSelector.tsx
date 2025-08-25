'use client';

import React from 'react';
import Image from 'next/image';
import { tokens as erc20Tokens, Token } from '@/utils/tokens';

// Define a default ETH-like object to represent native ETH
const ETH_TOKEN: Token = {
  name: 'Ethereum',
  symbol: 'ETH',
  address: '0x0000000000000000000000000000000000000000',
  decimals: 18,
  logoURI: 'https://assets.coingecko.com/coins/images/279/small/ethereum.png',
};

// Combine ETH with the other tokens
const allTokens = [ETH_TOKEN, ...erc20Tokens];

interface TokenSelectorProps {
  isOpen: boolean;
  onClose: () => void;
  onSelectToken: (token: Token) => void;
}

export function TokenSelector({ isOpen, onClose, onSelectToken }: TokenSelectorProps) {
  if (!isOpen) return null;

  const handleSelect = (token: Token) => {
    onSelectToken(token);
    onClose();
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 backdrop-blur-sm flex items-center justify-center z-50">
      <div className="bg-gray-800 border border-gray-700 rounded-2xl w-full max-w-sm p-4">
        <div className="flex justify-between items-center mb-4">
          <h3 className="text-lg font-bold text-white">Select a token</h3>
          <button onClick={onClose} className="text-gray-400 hover:text-white text-2xl leading-none">&times;</button>
        </div>
        <div className="flex flex-col space-y-2 max-h-96 overflow-y-auto">
          {allTokens.map((token) => (
            <div
              key={token.address}
              onClick={() => handleSelect(token)}
              className="flex items-center p-2 rounded-lg hover:bg-gray-700 cursor-pointer"
            >
              <Image src={token.logoURI} alt={token.name} width={32} height={32} className="rounded-full mr-4" unoptimized />
              <div>
                <p className="font-bold text-white">{token.symbol}</p>
                <p className="text-sm text-gray-400">{token.name}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}