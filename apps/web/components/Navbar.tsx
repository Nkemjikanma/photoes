import { ModeToggle } from "./ModeToggle";
import { PhotoFrame } from "./assets/PhotoFrame";
import { Separator } from "./ui/separator";
import { LocalConnectButton } from "./web3/LocalConnectButton";

export const Navbar = () => {
	return (
		<nav className="flex flex-col items-center justify-center py-3 font-bold gap-2 w-5/6">
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
					<div className="flex-initial">
						<LocalConnectButton />
					</div>
				</div>
			</div>
		</nav>
	);
};
