import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import localFont from "next/font/local";
import "./globals.css";
import { Web3Provider } from "@/providers/Web3Provider";

const commitMono400 = localFont({
	src: "../public/fonts/CommitMono-400-Regular.otf",
	variable: "--commit-mono-400",
});
const commitMono700 = localFont({
	src: "../public/fonts/CommitMono-700-Regular.otf",
	variable: "--commit-mono-700",
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
		<html lang="en">
			<body className={`${commitMono400.variable} ${commitMono700.variable} antialiased`}>
				<Web3Provider>{children}</Web3Provider>
			</body>
		</html>
	);
}
