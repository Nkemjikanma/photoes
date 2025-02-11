import Link from "next/link";

const links = [
	{
		name: "Github",
		logo: "/images/logos/github.svg",
		profile: "https://github.com/Nkemjikanma",
	},
	{
		name: "Farcaster",
		logo: "/images/logos/farcaster.svg",
		profile: "https://warpcast.com/nkemjika",
	},
];

export const ens = {
	domains: ["nkemjika.eth", "nkem.eth", "keyof.eth"],
};

export default function Footer() {
	return (
		<footer className="relative flex w-full items-end">
			<div className="mx-auto max-w-3xl flex flex-col gap-1 items-center justify-center">
				<div className="relative max-w-[600px] text-gray-600 dark:text-white text-sm">
					Made with love - nkemjika&copy; 🧌
				</div>
				<nav className="relative flex flex-row dark:text-white">
					{links.map((link, index) => (
						<Link
							key={link.name}
							href={link.profile}
							className={`text-sm text-gray-600 dark:text-white hover:text-gray-900 border-gray-200 dark:border-gray-800 px-4 ${index + 1 === links.length ? "border-r-0" : "border-r"}`}
						>
							{link.name}
						</Link>
					))}
				</nav>
			</div>
		</footer>
	);
}
