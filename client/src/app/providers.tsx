'use client';

import { WagmiConfig, createConfig } from 'wagmi';
import { mainnet, polygon, optimism, sepolia } from 'viem/chains'; // <-- Import sepolia
import { ConnectKitProvider, getDefaultConfig } from 'connectkit';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

const queryClient = new QueryClient();

const config = createConfig(
  getDefaultConfig({
    appName: 'Mercurius DEX',
    // Add Sepolia to the list of supported chains
    chains: [mainnet, sepolia, polygon, optimism],
    walletConnectProjectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID!,
  })
);

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <WagmiConfig config={config}>
      <QueryClientProvider client={queryClient}>
        <ConnectKitProvider
          theme="midnight" // Optional: A nice dark theme for our UI
        >
          {children}
        </ConnectKitProvider>
      </QueryClientProvider>
    </WagmiConfig>
  );
}