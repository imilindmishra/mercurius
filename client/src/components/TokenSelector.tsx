'use client';

import React from 'react';
import Image from 'next/image';
import { Token } from '@/utils/tokens';

export interface TokenSelectorProps {
  isOpen: boolean;
  onClose: () => void;
  onSelectToken: (token: Token) => void;
  tokens: Token[];
}

export function TokenSelector({ isOpen, onClose, onSelectToken, tokens }: TokenSelectorProps) {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-75 z-50 flex items-center justify-center p-4">
      <div className="bg-gray-800 rounded-lg w-full max-w-sm">
        <div className="p-4 border-b border-gray-700 flex justify-between items-center">
          <h2 className="text-lg font-semibold text-white">Select a token</h2>
          <button onClick={onClose} className="text-gray-400 hover:text-white">&times;</button>
        </div>
        <div className="p-2 max-h-96 overflow-y-auto">
          {tokens.map((token) => (
            <button
              key={token.address}
              onClick={() => onSelectToken(token)}
              className="w-full flex items-center p-3 text-left hover:bg-gray-700 rounded-lg"
            >
              <Image 
                src={token.logoURI} 
                alt={token.name} 
                className="w-8 h-8 rounded-full mr-4"
                width={32}
                height={32}
              />
              <div>
                <p className="font-bold text-white">{token.symbol}</p>
                <p className="text-sm text-gray-400">{token.name}</p>
              </div>
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}