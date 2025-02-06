"use client";
import { Main } from "@/components/Main";
import { Navbar } from "@/components/Navbar";
import { Separator } from "@/components/ui/separator";
import Link from "next/link";
import { useActiveAccount } from "thirdweb/react";

export default function Home() {
	const account = useActiveAccount();

	return (
		<div>
			{/* Main */}
			<main className="layout w-full flex flex-col justify-center h-full">
				<Main />
			</main>
		</div>
	);
}
