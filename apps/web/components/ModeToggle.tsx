"use client";

import { Moon, MoonIcon, Sun } from "lucide-react";
import { useTheme } from "next-themes";
import * as React from "react";

import { Button } from "@/components/ui/button";
import {
	DropdownMenu,
	DropdownMenuContent,
	DropdownMenuItem,
	DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";

export function ModeToggle() {
	const { setTheme } = useTheme();

	const themeList = ["Light", "Dark", "System"];

	return (
		<DropdownMenu>
			<DropdownMenuTrigger asChild>
				<Button
					variant="outline"
					size="icon"
					className="rounded-none border border-zinc-200 dark:border-zinc-800 hover:bg-gray-100 dark:hover:bg-zinc-900 focus:border-0 outline-zinc-200"
				>
					<Sun className="h-[1.2rem] w-[1.2rem] rotate-0 scale-100 transition-all dark:-rotate-90 dark:scale-0 rounded-none" />
					<Moon className="absolute h-[1.2rem] w-[1.2rem] rotate-90 scale-0 transition-all dark:rotate-0 dark:scale-100" />
					<span className="sr-only">Toggle theme</span>
				</Button>
			</DropdownMenuTrigger>
			<DropdownMenuContent
				align="end"
				className="rounded-none border-zinc-200 dark:border-zinc-800 p-0"
			>
				{themeList.map((themeItem, index) => (
					<DropdownMenuItem
						className="hover:bg-gray-100 dark:hover:bg-zinc-900"
						onClick={() => setTheme(themeItem.toLowerCase())}
						key={themeItem}
					>
						{themeItem}
					</DropdownMenuItem>
				))}
			</DropdownMenuContent>
		</DropdownMenu>
	);
}

// <DropdownMenuItem onClick={() => setTheme("dark")}>Dark</DropdownMenuItem>
// <DropdownMenuItem onClick={() => setTheme("system")}>System</DropdownMenuItem>
