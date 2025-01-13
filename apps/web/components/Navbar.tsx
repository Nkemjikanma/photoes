import { ModeToggle } from "./ModeToggle";
import { PhotoFrame } from "./assets/PhotoFrame";
import { Separator } from "./ui/separator";
import { LocalConnectButton } from "./web3/LocalConnectButton";

export const Navbar = () => {
	return (
		<nav className="w-full flex flex-col items-center justify-center py-3 font-bold gap-2">
			<div className="w-5/6 items-center justify-center flex flex-row">
				<div className="flex flex-1 items-center">
					<a
						href="/"
						className="flex items-center gap-1 w-fit p-1 h5 text-zinc-600 hover:text-zinc-900 dark:hover:text-zinc-200 transition-all"
					>
						<PhotoFrame size="20px" />
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
