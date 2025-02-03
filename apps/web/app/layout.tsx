import type { Metadata } from "next";
import localFont from "next/font/local";
import "./globals.css";
import { ThemeProvider } from "@/providers/ThemeProvider";
import { ThirdwebProvider } from "thirdweb/react";

// Font definition
const commitMono = localFont({
	src: [
		{
			path: "../public/fonts/CommitMono-400-Regular.otf",
			weight: "400",
			style: "normal",
		},
		{
			path: "../public/fonts/CommitMono-700-Regular.otf",
			weight: "700",
			style: "normal",
		},
	],
	variable: "--font-commit-mono",
});

export const metadata: Metadata = {
	title: "Photoes",
	description: "Photoes by Nkmejika",
};

export default function RootLayout({
	children,
}: Readonly<{
	children: React.ReactNode;
}>) {
	return (
		<html lang="en" suppressHydrationWarning>
			<body
				className={`${commitMono.variable} font-sans antialiased bg-grey text-zinc-800 dark:text-zinc-200 dark:bg-black`}
			>
				<ThemeProvider attribute="class" defaultTheme="dark" enableSystem disableTransitionOnChange>
					<ThirdwebProvider>{children}</ThirdwebProvider>
				</ThemeProvider>
			</body>
		</html>
	);
}
