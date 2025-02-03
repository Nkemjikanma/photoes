import { Button } from "@/components/ui/button";
import { client } from "@/lib/client";
import { useTheme } from "next-themes";
import { forwardRef } from "react";
import { type ChainOptions, base, baseSepolia, ethereum } from "thirdweb/chains";
import { AutoConnect, ConnectButton, darkTheme, lightTheme, useConnect } from "thirdweb/react";
import { createWallet, inAppWallet } from "thirdweb/wallets";

const wallets = [
	createWallet("io.metamask"),
	createWallet("com.coinbase.wallet"),
	createWallet("me.rainbow"),
];

interface LocalConnectButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
	customProps?: string;
}

export const LocalConnectButton = forwardRef<HTMLButtonElement, LocalConnectButtonProps>(
	({ className, style, ...props }, ref) => {
		const appChain: typeof base = process.env.NODE_ENV === "development" ? baseSepolia : base;

		return (
			<ConnectButton
				client={client}
				appMetadata={{
					name: "Esemese.xyz",
					logoUrl: "https://esemese.xyz",
					url: "https://esemese.xyz",
					description: "Photography gallery for Nkemjika",
				}}
				connectButton={{
					style: {
						borderRadius: "0px",
						padding: "10px 16px",
						height: "fit-content",
						...style,
					},
				}}
				connectModal={{
					size: "wide",
				}}
				chain={appChain}
				autoConnect={{ timeout: 15000 }}
				walletConnect={{
					projectId: process.env.NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID,
				}}
				wallets={wallets}
				// theme={currentTheme}
				// auth={{
				// 	isLoggedIn: async (address) => {
				// 		console.log("checking if logged in!", { address });
				// 		return await isLoggedIn();
				// 	},
				// 	doLogin: async (params) => {
				// 		console.log("logging in!");
				// 		await login(params);
				// 	},
				// 	getLoginPayload: async ({ address }) => generatePayload({ address }),
				// 	doLogout: async () => {
				// 		console.log("logging out!");
				// 		await logout();
				// 	},
				// }}
				{...props}
			/>
		);
	},
);
LocalConnectButton.displayName = "LocalConnectionButton";
