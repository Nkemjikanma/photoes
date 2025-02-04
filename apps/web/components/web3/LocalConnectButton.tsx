import { client } from "@/lib/client";
import { generatePayload, isLoggedIn, login, logout } from "./actions/auth";

import { useTheme } from "next-themes";
import { defineChain } from "thirdweb";
import { base, baseSepolia } from "thirdweb/chains";
import { AutoConnect, ConnectButton, darkTheme, lightTheme, useConnect } from "thirdweb/react";

export const LocalConnectButton = () => {
	const { theme } = useTheme();
	const appChain: typeof base = process.env.NODE_ENV === "development" ? baseSepolia : base;

	return (
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
			auth={{
				isLoggedIn: async (address) => {
					console.log("checking if logged in!", { address });
					return await isLoggedIn();
				},
				doLogin: async (params) => {
					console.log("logging in!");
					await login(params);
				},
				getLoginPayload: async ({ address }) => generatePayload({ address, chainId: appChain.id }),
				doLogout: async () => {
					console.log("logging out!");
					await logout();
				},
			}}
			connectButton={{
				style: {
					borderRadius: "0px",
					padding: "10px 16px",
					height: "fit-content",
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
					borderRadius: "0px",
					padding: "2px",

					height: "fit-content",
				},
				// connectedAccountAvatarUrl,
			}}
			theme={theme === "light" ? "light" : "dark"}
		/>
	);
};
