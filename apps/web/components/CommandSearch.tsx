import { useEffect, useState } from "react";

import { useRouter } from "next/navigation";

import {
	CommandDialog,
	CommandEmpty,
	CommandGroup,
	CommandInput,
	CommandItem,
	CommandList,
	CommandSeparator,
	CommandShortcut,
} from "@/components/ui/command";

import { DialogHeader, DialogTitle } from "@/components/ui/dialog";

import { Calculator, Calendar, CreditCard, Search, Settings, Smile, User } from "lucide-react";

export const CommandSearch = () => {
	const [open, setOpen] = useState(false);
	const router = useRouter();

	useEffect(() => {
		const down = (event: KeyboardEvent) => {
			if ((event.key === "k" && event.metaKey) || event.ctrlKey) {
				event.preventDefault();
				setOpen((open) => !open);
			}
		};

		document.addEventListener("keydown", down);
		return () => document.removeEventListener("keydown", down);
	}, []);

	const runCommand = (command: () => void) => {
		setOpen(false);
		command();
	};

	return (
		<>
			<p className="relative flex flex-row px-4 py-2 items-center justify-center bg-amber-600 text-muted-foreground font-semibold">
				<Search width={16} height={16} className="mr-2" />
				<kbd className="pointer-events-none inline-flex h-5 select-none items-center gap-1 rounded-none bg-muted ">
					<span className="">⌘</span>K
				</kbd>
			</p>
			<CommandDialog open={open} onOpenChange={setOpen}>
				<DialogHeader>
					<DialogTitle className="sr-only">Command Menu</DialogTitle>
				</DialogHeader>
				<CommandInput placeholder="Type a command or search..." />
				<CommandList>
					<CommandEmpty>No results found.</CommandEmpty>
					<CommandGroup heading="Suggestions">
						<CommandItem
							onSelect={() => {
								setOpen(false);
								router.push("/");
							}}
						>
							<Calendar className="mr-2 h-4 w-4" />
							<span>Calendar</span>
						</CommandItem>
						<CommandItem
							onSelect={() => {
								setOpen(false);
							}}
						>
							<Smile className="mr-2 h-4 w-4" />
							<span>Search Emoji</span>
						</CommandItem>
						<CommandItem
							onSelect={() => {
								setOpen(false);
							}}
						>
							<Calculator className="mr-2 h-4 w-4" />
							<span>Calculator</span>
						</CommandItem>
					</CommandGroup>
					<CommandSeparator />
					<CommandGroup heading="Settings">
						<CommandItem
							onSelect={() => {
								setOpen(false);
							}}
						>
							<User className="mr-2 h-4 w-4" />
							<span>Profile</span>
							<CommandShortcut>⌘P</CommandShortcut>
						</CommandItem>
						<CommandItem
							onSelect={() => {
								setOpen(false);
							}}
						>
							<CreditCard className="mr-2 h-4 w-4" />
							<span>Billing</span>
							<CommandShortcut>⌘B</CommandShortcut>
						</CommandItem>
						<CommandItem
							onSelect={() => {
								setOpen(false);
							}}
						>
							<Settings className="mr-2 h-4 w-4" />
							<span>Settings</span>
							<CommandShortcut>⌘S</CommandShortcut>
						</CommandItem>
					</CommandGroup>
				</CommandList>
			</CommandDialog>
		</>
	);
};
