"use client";
import { generatePayload, isLoggedIn, login, logout } from "@/lib/auth";
import { client } from "@/lib/client";
import { useEffect, useState } from "react";

import { useTheme } from "next-themes";
import { base, baseSepolia } from "thirdweb/chains";
import { AutoConnect, ConnectButton, darkTheme, lightTheme, useConnect } from "thirdweb/react";
import { createWallet } from "thirdweb/wallets";

export const LocalConnectButton = () => {
	const { theme } = useTheme();

	const [mounted, setMounted] = useState(false);

	useEffect(() => {
		setMounted(true);
	}, []);

	// Don't render anything until mounted to prevent hydration mismatch
	if (!mounted) {
		return null;
	}

	const appChain: typeof base = process.env.NODE_ENV === "development" ? baseSepolia : base;

	const wallets = [
		// inAppWallet(),
		createWallet("io.metamask"),
		createWallet("com.coinbase.wallet"),
		createWallet("me.rainbow"),
	];

	return (
		<div className="relative h-fit min-w-24 rounded-none hover:bg-gray-100 border-zinc-200 dark:border-zinc-800 dark:hover:bg-zinc-900">
			<ConnectButton
				appMetadata={{
					name: "Esemese.xyz",
					logoUrl: "https://esemese.xyz",
					url: "https://esemese.xyz",
					description: "Photography gallery for Nkemjika",
				}}
				client={client}
				// accountAbstraction={{
				// 	chain: defineChain(appChain.id),
				// 	sponsorGas: false,
				// }}
				wallets={wallets}
				auth={{
					isLoggedIn: async (address) => {
						console.log("checking if logged in!", { address });
						return await isLoggedIn();
					},
					doLogin: async (params) => {
						console.log("logging in!");
						await login(params);
					},
					getLoginPayload: async ({ address }) =>
						generatePayload({ address, chainId: appChain.id }),
					doLogout: async () => {
						console.log("logging out!");
						await logout();
					},
				}}
				connectButton={{
					label: "sign-in",
					className: ".connect-button",
					style: {
						border: theme === "light" ? "1px solid #e4e4e7" : "1px solid #27272a",
						borderRadius: "0px",
						padding: "2px",
						height: "41px",
						background: "transparent",
						color: theme === "light" ? "#000000" : "#ffffff",
					},
				}}
				chain={appChain}
				autoConnect={{ timeout: 15000 }}
				walletConnect={{
					projectId: process.env.NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID,
				}}
				detailsButton={{
					className: "rounded-none",
					style: {
						border: theme === "light" ? "1px solid #e4e4e7" : "1px solid #27272a",
						borderRadius: "0px",
						padding: "2px",
						height: "41px",
						background: "transparent",
						color: theme === "light" ? "#000000" : "#ffffff",
					},
				}}
				connectModal={{
					title: "Connect wallet",
					size: "compact",
				}}
				theme={theme === "light" ? "light" : "dark"}
				detailsModal={{
					showTestnetFaucet: true,
				}}
			/>
		</div>
	);
};
