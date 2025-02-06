import { Navbar } from "@/components/Navbar";
import { Separator } from "@/components/ui/separator";
import Link from "next/link";
import type { ReactNode } from "react";
import { useActiveAccount } from "thirdweb/react";

export default function HomeLayout({ children }: { children: ReactNode }) {
	// const account = useActiveAccount();
	return (
		<div className="flex flex-col justify-center items-center min-w-96 mx-auto">
			<div className="h-1/12 w-full flex flex-col items-center">
				<Navbar />
				<Separator className="w-full" />
			</div>
			{children} {/* Footer */}
			<footer className="h-1/12 w-full p-3">
				{/* <Link href={`/${account?.address}`}>Profile</Link> */}
				<p>here</p>

				{/* Footer content goes here */}
			</footer>
		</div>
	);
}
