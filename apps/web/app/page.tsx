"use client";
import { Main } from "@/components/Main";
import { Navbar } from "@/components/Navbar";
import { Separator } from "@/components/ui/separator";

export default function Home() {
	return (
		<div className="flex flex-col justify-center items-center min-w-96 mx-auto">
			<div className="h-1/12 w-full flex flex-col items-center">
				<Navbar />
				<Separator className="w-full" />
			</div>

			{/* Main */}
			<main className="layout w-full flex flex-col justify-center h-full">
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
