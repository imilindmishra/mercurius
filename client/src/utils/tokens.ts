// client/src/utils/tokens.ts

export interface Token {
  name: string;
  symbol: string;
  address: `0x${string}`;
  decimals: number;
  logoURI: string;
}

export const ETH_TOKEN: Token = {
  name: 'Ethereum',
  symbol: 'ETH',
  address: '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE', 
  decimals: 18,
  logoURI: 'https://assets.coingecko.com/coins/images/279/small/ethereum.png',
};

export const WETH_TOKEN: Token = {
  name: 'Wrapped Ether',
  symbol: 'WETH',
  address: '0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14',
  decimals: 18,
  logoURI: 'https://assets.coingecko.com/coins/images/279/small/ethereum.png',
};

export const USDC_TOKEN: Token = {
  name: 'USD Coin',
  symbol: 'USDC',
  // CORRECTED: Used the valid EIP-55 checksum address
  address: '0x1C7D4B196cB0c7B01D743FBC6116a902379C7a90',
  decimals: 6,
  logoURI: 'https://assets.coingecko.com/coins/images/6319/small/USD_Coin_icon.png',
};

export const TOKENS: Token[] = [ETH_TOKEN, WETH_TOKEN, USDC_TOKEN];