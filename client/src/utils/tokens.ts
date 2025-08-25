// client/src/utils/tokens.ts

export interface Token {
  name: string;
  symbol: string;
  address: `0x${string}`; // Use the `0x` prefixed string type
  decimals: number;
  logoURI: string;
}

// A common Sepolia WETH address
export const WETH_TOKEN: Token = {
  name: 'Wrapped Ether',
  symbol: 'WETH',
  address: '0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14',
  decimals: 18,
  logoURI: 'https://assets.coingecko.com/coins/images/279/small/ethereum.png',
};

// A common Sepolia USDC address
// ❗️ IMPORTANT: Replace this with the actual address of your USDC token on Sepolia
export const USDC_TOKEN: Token = {
  name: 'USD Coin',
  symbol: 'USDC',
  address: '0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7a90',
  decimals: 6, // USDC typically has 6 decimals
  logoURI: 'https://assets.coingecko.com/coins/images/6319/small/USD_Coin_icon.png',
};

// The list of tokens you want to make available in the TokenSelector
export const TOKENS: Token[] = [WETH_TOKEN, USDC_TOKEN];