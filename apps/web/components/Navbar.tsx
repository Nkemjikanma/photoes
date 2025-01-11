import { ModeToggle } from "./ModeToggle";
import { LocalConnectButton } from "./web3/LocalConnectButton";

export const Navbar = () => {
	return (
		<nav className="w-full flex justify-center py-4">
			<div className="w-5/6 items-center justify-center flex flex-row">
				<div className="flex flex-1">
					<a
						href="/"
						className="w-fit p-1 h4 text-zinc-600 hover:text-zinc-900 dark:hover:text-zinc-200 transition-all"
					>
						Photoes
					</a>
				</div>
				<div className="flex flex-row gap-2">
					<ModeToggle />
					<div className="flex-initial">
						<LocalConnectButton />
					</div>
				</div>
			</div>
		</nav>
	);
};
