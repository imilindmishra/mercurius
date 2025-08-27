// src/components/TokenSelector.tsx

'use client';

import React from 'react';
import Image from 'next/image';
// CORRECTED: We only need the `Token` type, not the array
import { Token } from '@/utils/tokens';

// CORRECTED: Added `tokens: Token[]` to the props interface
interface TokenSelectorProps {
  isOpen: boolean;
  onClose: () => void;
  onSelectToken: (token: Token) => void;
  tokens: Token[];
}

// CORRECTED: Destructure `tokens` from the props
export function TokenSelector({ isOpen, onClose, onSelectToken, tokens }: TokenSelectorProps) {
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
          <button onClick={onClose} className="text-gray-400 hover:text-white">&times;</button>
        </div>
        <div className="flex flex-col space-y-2 max-h-96 overflow-y-auto">
          {/* This will now correctly map over the `tokens` array passed via props */}
          {tokens.map((token) => (
            <div
              key={token.address}
              onClick={() => handleSelect(token)}
              className="flex items-center p-2 rounded-lg hover:bg-gray-700 cursor-pointer"
            >
              <Image src={token.logoURI} alt={token.name} className="w-8 h-8 rounded-full mr-4" width={32} height={32} />
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