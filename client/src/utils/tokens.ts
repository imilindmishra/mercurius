export interface Token {
  name: string;
  symbol: string;
  address: `0x${string}`;
  decimals: number;
  logoURI: string;
}

// UPDATED with your new token addresses from the deployment
const KAJU_ADDRESS = '0x3C8Dd7870E9a8e7e996543C4ADeB643438D4Aba8';
const BRFI_ADDRESS = '0xE6DC9225E4C76f9c0b002Ab2782F687e35cc7666';

export const KAJU_TOKEN: Token = {
  name: 'KAJUCOIN',
  symbol: 'KAJU',
  address: KAJU_ADDRESS,
  decimals: 18,
  logoURI: '/placeholder-logo-1.png',
};

export const BRFI_TOKEN: Token = {
  name: 'BRFICOIN',
  symbol: 'BRFI',
  address: BRFI_ADDRESS,
  decimals: 18,
  logoURI: '/placeholder-logo-2.png',
};

export const TOKENS: Token[] = [KAJU_TOKEN, BRFI_TOKEN];