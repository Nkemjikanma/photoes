import Footer from "@/components/Footer";
import { Navbar } from "@/components/Navbar";
import { Separator } from "@/components/ui/separator";
import dynamic from "next/dynamic";
import Link from "next/link";
import type { ReactNode } from "react";
import { useActiveAccount } from "thirdweb/react";

export default function HomeLayout({ children }: { children: ReactNode }) {
	// const account = useActiveAccount();
	return (
		<div className="flex flex-col min-h-screen justify-center items-center min-w-96 mx-auto">
			<div className="h-1/12 w-full flex flex-col items-center">
				<Navbar />
			</div>
			<main className="layout w-full flex flex-grow flex-col justify-center">{children}</main>
			<footer className="h-1/12 w-full mt-4">
				<Footer />
			</footer>
		</div>
	);
}
