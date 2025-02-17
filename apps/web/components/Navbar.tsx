"use client";

import { PersonStanding, PersonStandingIcon, Sun } from "lucide-react";
import Link from "next/link";
import { useEffect, useState } from "react";
import { useActiveAccount } from "thirdweb/react";
import { ModeToggle } from "./ModeToggle";
import { PhotoFrame } from "./assets/PhotoFrame";
import { LocalConnectButton } from "./web3/LocalConnectButton";

export const Navbar = () => {
	const [mounted, setMounted] = useState(false);

	useEffect(() => {
		setMounted(true);
	}, []);
	const account = useActiveAccount();
	const isLoggedIn = !!account;

	// if (!mounted) {
	// 	return (
	// 		<nav className="flex flex-col items-center justify-center py-3 px-4 md:px-0 font-bold gap-2 w-10/12 min-w-96">
	// 			<div className="w-full items-center justify-center flex flex-row animate-pulse border border-red-200">
	// 				{/* Skeleton loading state */}
	// 				<div className="flex-1 h-8 bg-gray-100 dark:bg-zinc-800 rounded-none" />
	// 				<div className="flex gap-2">
	// 					<div className="w-10 h-10 bg-gray-200 dark:bg-zinc-800 rounded-none" />
	// 					<div className="w-10 h-10 bg-gray-200 dark:bg-zinc-800 rounded-none" />
	// 					<div className="w-10 h-10 bg-gray-200 dark:bg-zinc-800 rounded-none" />
	// 				</div>
	// 			</div>
	// 		</nav>
	// 	);
	// }

	return (
		<nav className="flex flex-col items-center justify-center py-3 px-4 md:px-0 font-bold gap-2 w-10/12 min-w-96 transition-all duration-300">
			<div className="w-full items-center justify-center flex flex-row">
				<div className="flex flex-1 items-center">
					<a
						href="/"
						className="antialiased flex items-center gap-1 w-fit p-1 h5 text-zinc-600 hover:text-zinc-900 dark:hover:text-amber-700 transition-all font-normal dark:text-amber-600"
					>
						<PhotoFrame width="20px" height="30px" />
						Esemese
					</a>
				</div>
				{mounted ? (
					<div className="flex flex-row gap-2 minw-[262px] h-fit">
						{account?.address && (
							<Link
								href={`/${account?.address}`}
								className="relative flex items-center justify-center h-10 w-10  rounded-none border border-zinc-200 dark:border-zinc-800 hover:bg-gray-100 dark:hover:bg-zinc-900 focus:border-0 outline-zinc-200"
							>
								<PersonStanding className="" />
								<span className="sr-only">Profile link</span>
							</Link>
						)}

						<ModeToggle />
						<div className="hidden md:block w-[167px]">
							<LocalConnectButton />
						</div>
					</div>
				) : (
					<div className="flex gap-2">
						<div className="w-10 h-9 bg-gray-200 dark:bg-zinc-800 rounded-none" />
						<div className="w-10 h-9 bg-gray-200 dark:bg-zinc-800 rounded-none" />
						<div className="w-25 h-9 bg-gray-200 dark:bg-zinc-800 rounded-none mr-10" />
					</div>
				)}
			</div>
		</nav>
	);
};
