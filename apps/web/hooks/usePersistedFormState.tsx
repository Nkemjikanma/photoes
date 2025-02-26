import { format } from "node:path/posix";
import type { UploadFormType } from "@/app/(home)/(account)/[userAccount]/_components/UploadForm";
import { useCallback, useEffect, useState } from "react";

// Define strict types for stored data
type StoredPhotoData = Omit<NonNullable<UploadFormType["photos"][number]>, "photo">;

type StoredSingleFormData = {
	type: "single";
	photos: StoredPhotoData[];
	groupId?: string;
};

type StoredCollectionFormData = {
	type: "collection";
	photos: StoredPhotoData[];
	collectionName: string;
	collectionDescription: string;
};

type StoredFormData = StoredSingleFormData | StoredCollectionFormData;

interface StoredState {
	formData: Partial<StoredFormData> | null;
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

	useEffect(() => {
		try {
			const saved = localStorage.getItem(FORM_STORAGE_KEY);
			if (saved) {
				setStoredState(JSON.parse(saved));
			}
		} catch (e) {
			console.error("Failed to load form state:", e);
		}
	}, []);

	const updateState = useCallback((newState: Partial<StoredState>) => {
		setStoredState((prev) => {
			const updated = { ...prev, ...newState };
			if (typeof window !== "undefined") {
				try {
					const sanitizedState = {
						...updated,
						formData: updated.formData
							? {
									...updated.formData,
									photos: updated.formData.photos?.map((photo: any) => {
										// Use type assertion and omit photo property
										const { photo: photoFile, ...rest } = photo;
										return rest;
									}),
								}
							: null,
					};
					localStorage.setItem(FORM_STORAGE_KEY, JSON.stringify(sanitizedState));
				} catch (e) {
					console.error("Failed to save form state:", e);
				}
			}
			return updated;
		});
	}, []);

	const clearState = useCallback(() => {
		if (typeof window !== "undefined") {
			try {
				localStorage.removeItem(FORM_STORAGE_KEY);
			} catch (e) {
				console.error("Failed to clear form state:", e);
			}
		}
		setStoredState({ formData: null });
	}, []);

	return {
		storedState,
		updateState,
		clearState,
	};
};
