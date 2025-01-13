"use client";
import { Main } from "@/components/Main";
import { Navbar } from "@/components/Navbar";
import { Separator } from "@/components/ui/separator";
import { LocalConnectButton } from "@/components/web3/LocalConnectButton";
import { ConnectKitButton } from "connectkit";
import Image from "next/image";

export default function Home() {
	return (
		<div className="flex flex-col items-center h-screen">
			<div className="h-1/12 w-full">
				<Navbar />
				<Separator className="w-full" />
			</div>

			{/* Main */}
			<main className="layout w-full flex flex-row justify-center h-full">
				<Main />
			</main>

			{/* Footer */}
			<footer className="h-1/12 w-full p-3">
				<p>here</p>
				{/* Footer content goes here */}
			</footer>
		</div>
	);
}
