import { type ClassValue, clsx } from "clsx";
import { twMerge } from "tailwind-merge";
import { CollectionCategory } from "./types";

export function cn(...inputs: ClassValue[]) {
	return twMerge(clsx(inputs));
}

export const sanitizeTags = (tag: string) => {
	// Convert to lowercase and trim whitespace
	// Remove special characters, allow only letters, numbers, and hyphens
	return tag
		.toLowerCase()
		.trim()
		.replace(/[^a-z0-9-\s]/g, "")
		.replace(/\s+/g, "-");
};

export const isValidTag = (tag: string) => {
	const sanitized = sanitizeTags(tag);

	return sanitized.length >= 2 && sanitized.length <= 32 && /[a-z]/.test(sanitized);
};

export const getTagSuggestions = (input: string | unknown, localTags: string[]): string[] => {
	// Handle case where input is not a string
	const searchInput = typeof input === "string" ? input : "";

	const commonTags = Object.values(CollectionCategory);

	return commonTags.filter(
		(tag) => tag.toLowerCase().startsWith(searchInput.toLowerCase()) && !localTags.includes(tag),
	);
};
