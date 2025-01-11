"use client";
import { Main } from "@/components/Main";
import { Navbar } from "@/components/Navbar";
import { LocalConnectButton } from "@/components/web3/LocalConnectButton";
import { ConnectKitButton } from "connectkit";
import Image from "next/image";

export default function Home() {
	return (
		<div className="flex flex-col items-center border-red-400">
			<Navbar />

			{/* Main */}
			<main className="layout w-full flex flex-row justify-center">
				<Main />
			</main>

			{/*Footer */}
		</div>
	);
}
