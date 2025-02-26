"use client";

import { Check, ChevronsUpDown, X } from "lucide-react";
import * as React from "react";
import { type ComponentProps, type ElementRef, useRef } from "react";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
	Command,
	CommandEmpty,
	CommandGroup,
	CommandInput,
	CommandItem,
	CommandList,
} from "@/components/ui/command";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { CollectionCategory } from "@/lib/types";
import { cn } from "@/lib/utils";
import { type FieldMetadata, unstable_useControl as useControl } from "@conform-to/react";

interface MultiSelectProps {
	meta: FieldMetadata;
	options?: string[];
	placeholder?: string;
	emptyPlaceholder?: string;
	defaultValue?: string[];
}

export const MultiSelect = ({
	options = Object.values(CollectionCategory),
	placeholder = "Select a tag",
	emptyPlaceholder = "Not tags found",
	defaultValue = [],
	meta,
}: MultiSelectProps & ComponentProps<typeof PopoverTrigger>) => {
	const popupRef = useRef<ElementRef<typeof PopoverTrigger>>(null);
	const control = useControl(meta);

	const [open, setOpen] = React.useState(false);
	const [selectedItems, setSelectedItems] = React.useState<string[]>(() => {
		// Parse initial value if it's a string
		if (typeof meta.value === "string") {
			try {
				const parsed = JSON.parse(meta.value);
				return Array.isArray(parsed) ? parsed : defaultValue;
			} catch {
				return defaultValue;
			}
		}
		return Array.isArray(meta.value) ? meta.value : defaultValue;
	});

	const [inputValue, setInputValue] = React.useState("");

	const handleSelect = React.useCallback(
		(item: string) => {
			setSelectedItems((prev) => {
				const newItems = prev.includes(item) ? prev.filter((i) => i !== item) : [...prev, item];
				control.change(JSON.stringify(newItems)); // Use control instead of manual DOM manipulation
				return newItems;
			});
		},
		[control],
	);

	const handleRemove = React.useCallback(
		(item: string) => {
			setSelectedItems((prev) => {
				const newItems = prev.filter((i) => i !== item);
				control.change(JSON.stringify(newItems)); // Use control instead of manual DOM manipulation
				return newItems;
			});
		},
		[control],
	);

	const handleKeyDown = React.useCallback(
		(e: React.KeyboardEvent<HTMLInputElement>) => {
			if (
				e.key === "Enter" &&
				inputValue &&
				!options.includes(inputValue) &&
				!selectedItems.includes(inputValue)
			) {
				setSelectedItems((prev) => {
					const newItems = [...prev, inputValue];
					// Update the form field
					const input = document.createElement("input");
					input.type = "hidden";
					input.name = meta.name;
					input.value = JSON.stringify(newItems);
					document.getElementById(meta.formId)?.appendChild(input);
					return newItems;
				});
				setInputValue("");
			}
		},
		[inputValue, options, selectedItems, meta.name, meta.formId],
	);

	const filteredOptions = React.useMemo(() => {
		return options.filter(
			(option) =>
				option.toLowerCase().includes(inputValue.toLowerCase()) && !selectedItems.includes(option),
		);
	}, [options, inputValue, selectedItems]);

	const handleInputChange = React.useCallback((value: string) => {
		setInputValue(value);
	}, []);

	return (
		<div className="max-w-screen">
			<input type="hidden" name={meta.name} value={JSON.stringify(selectedItems)} />
			<Popover open={open} onOpenChange={setOpen}>
				<PopoverTrigger asChild>
					<Button
						variant="outline"
						role="combobox"
						aria-expanded={open}
						className={cn(
							"w-fit h-fit rounded-none justify-between",
							meta.errors ? "border-destructive" : "",
						)}
					>
						{selectedItems.length > 0 ? (
							<div className="flex flex-wrap gap-1">
								{selectedItems.map((item) => (
									<Badge key={item} variant="secondary" className="mr-1">
										{item}
										<span
											className="ml-1 ring-offset-background rounded-full outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2"
											onKeyDown={(e) => {
												if (e.key === "Enter") {
													handleRemove(item);
												}
											}}
											onMouseDown={(e) => {
												e.preventDefault();
												e.stopPropagation();
											}}
											onClick={(e) => {
												e.preventDefault();
												e.stopPropagation();
												handleRemove(item);
											}}
										>
											<X className="h-3 w-3 text-muted-foreground hover:text-foreground" />
										</span>
									</Badge>
								))}
							</div>
						) : (
							<span className="rounder-none text-muted-foreground">{placeholder}</span>
						)}
						<ChevronsUpDown className="ml-2 h-4 w-4 shrink-0 opacity-50" />
					</Button>
				</PopoverTrigger>
				<PopoverContent className="w-full p-0">
					<Command>
						<CommandInput
							placeholder="Search items..."
							value={inputValue}
							onValueChange={handleInputChange}
							onKeyDown={handleKeyDown}
						/>
						<CommandList>
							<CommandEmpty>{emptyPlaceholder}</CommandEmpty>
							<CommandGroup>
								{filteredOptions.map((option) => (
									<CommandItem key={option} value={option} onSelect={() => handleSelect(option)}>
										<Check
											className={cn(
												"mr-2 h-4 w-4",
												selectedItems.includes(option) ? "opacity-100" : "opacity-0",
											)}
										/>
										{option}
									</CommandItem>
								))}
							</CommandGroup>
						</CommandList>
					</Command>
				</PopoverContent>
			</Popover>
		</div>
	);
};
