"use client";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";

import { http, WagmiProvider, createConfig } from "wagmi";
import { base, baseSepolia } from "wagmi/chains";

import { ConnectKitProvider, getDefaultConfig } from "connectkit";

declare module "wagmi" {
	interface Register {
		config: typeof config;
	}
}

const chain = process.env.NODE_ENV === "development" ? baseSepolia : base;

export const config = createConfig(
	getDefaultConfig({
		chains: [chain],
		transports: {
			[base.id]: http(),
			[baseSepolia.id]: http(),
		},

		walletConnectProjectId: process.env.WALLET_CONNECT_PROJECT_ID as string,

		appName: "Photoes",

		appDescription: "Photoes by Nkemjika",
		appUrl: "https://photoes.xyz",
		appIcon: "", // your app's icon, no bigger than 1024x1024px (max. 1MB)s
	}),
);

// 2. Set up a React Query client.
const queryClient = new QueryClient();

export const Web3Provider = ({ children }: { children: React.ReactNode }) => {
	return (
		<WagmiProvider config={config}>
			<QueryClientProvider client={queryClient}>
				<ConnectKitProvider>{children}</ConnectKitProvider>
			</QueryClientProvider>
		</WagmiProvider>
	);
};
