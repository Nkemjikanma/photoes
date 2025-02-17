import { type ClassValue, clsx } from "clsx";
import { twMerge } from "tailwind-merge";

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

export const getTagSuggestions = (input: string, localTags: string[]): string[] => {
	// You could implement tag suggestions based on
	// commonly used tags or a predefined list
	const commonTags = [
		"nature",
		"landscape",
		"portrait",
		"street",
		"wildlife",
		"architecture",
		"travel",
		"macro",
	];

	return commonTags.filter(
		(tag) => tag.startsWith(input.toLowerCase()) && !localTags.includes(tag),
	);
};
