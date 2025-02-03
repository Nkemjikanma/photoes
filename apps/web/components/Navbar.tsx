import Link from "next/link";
import { useActiveAccount } from "thirdweb/react";
import { ModeToggle } from "./ModeToggle";
import { AddButton } from "./assets/AddButton";
import { PhotoFrame } from "./assets/PhotoFrame";
import { Separator } from "./ui/separator";
import { LocalConnectButton } from "./web3/LocalConnectButton";

export const Navbar = () => {
	const account = useActiveAccount();
	return (
		<nav className="flex flex-col items-center justify-center py-3 px-4 md:px-0 font-bold gap-2 w-10/12 min-w-96">
			<div className="w-full items-center justify-center flex flex-row">
				<div className="flex flex-1 items-center">
					<a
						href="/"
						className="flex items-center gap-1 w-fit p-1 h5 text-zinc-600 hover:text-zinc-900 dark:hover:text-amber-700 transition-all font-normal dark:text-amber-600"
					>
						<PhotoFrame width="20px" height="30px" />
						Esemese
					</a>
				</div>
				<div className="flex flex-row gap-2">
					<ModeToggle />
					<div className="hidden md:block">
						{account ? (
							<Link href={`/profile/${account?.address}`}>Profile</Link>
						) : (
							<LocalConnectButton style={{}} />
						)}
					</div>
				</div>
			</div>
		</nav>
	);
};
