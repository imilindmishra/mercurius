'use client';

import { WagmiConfig, createConfig } from 'wagmi';
// ADD `optimismSepolia` to your imports
import { mainnet, polygon, optimism, sepolia, arbitrumSepolia, optimismSepolia } from 'viem/chains';
import { ConnectKitProvider, getDefaultConfig } from 'connectkit';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

const queryClient = new QueryClient();

const config = createConfig(
  getDefaultConfig({
    appName: 'Mercurius DEX',
    // ADD `optimismSepolia` to the chains array
    chains: [mainnet, sepolia, arbitrumSepolia, optimismSepolia, polygon, optimism],
    walletConnectProjectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID!,
  })
);

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <WagmiConfig config={config}>
      <QueryClientProvider client={queryClient}>
        <ConnectKitProvider theme="midnight">
          {children}
        </ConnectKitProvider>
      </QueryClientProvider>
    </WagmiConfig>
  );
}