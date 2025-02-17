import type { UploadFormData } from "@/app/(home)/(account)/[userAccount]/_components/UploadForm";
import { useCallback, useEffect, useState } from "react";

// Define strict types for stored data
interface StoredState {
	formData: Partial<UploadFormData> | null;
}
const FORM_STORAGE_KEY = "photo-upload-form";

export const usePersistedFormState = () => {
	const [storedState, setStoredState] = useState<StoredState>(() => {
		if (typeof window === "undefined") return { formData: null };
		try {
			const saved = localStorage.getItem(FORM_STORAGE_KEY);
			return saved ? JSON.parse(saved) : { formData: null };
		} catch (e) {
			console.error("Failed to load form state:", e);
			return { formData: null };
		}
	});

	const updateState = useCallback((newState: Partial<StoredState>) => {
		setStoredState((prev) => {
			const updated = { ...prev, ...newState };
			if (typeof window !== "undefined") {
				try {
					localStorage.setItem(FORM_STORAGE_KEY, JSON.stringify(updated));
				} catch (e) {
					console.error("Failed to save form state:", e);
				}
			}
			return updated;
		});
	}, []);

	const clearState = useCallback(() => {
		if (typeof window !== "undefined") {
			localStorage.removeItem(FORM_STORAGE_KEY);
		}
		setStoredState({ formData: null });
	}, []);

	return {
		storedState,
		updateState,
		clearState,
	};
};
