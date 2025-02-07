import type { Metadata } from "next";
import "./globals.css";

import { ThemeProvider } from "@/providers/ThemeProvider";
import { ThirdwebProvider } from "thirdweb/react";

export const metadata: Metadata = {
	title: "Esemese",
	description: "Eseme by Nkmejika",
	other: {
		"style-preload": {
			type: "text/css",
			as: "style",
		},
	},
};

export default function RootLayout({
	children,
}: Readonly<{
	children: React.ReactNode;
}>) {
	return (
		<html lang="en" suppressHydrationWarning>
			<body
				className={
					"font-display antialiased bg-grey text-zinc-800 dark:text-zinc-200 dark:bg-black"
				}
			>
				<ThemeProvider attribute="class" defaultTheme="dark" enableSystem disableTransitionOnChange>
					<ThirdwebProvider>{children}</ThirdwebProvider>
				</ThemeProvider>
			</body>
		</html>
	);
}
