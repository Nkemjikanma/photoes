"use client";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import { usePersistedFormState } from "@/hooks/usePersistedFormState";
import {
	CollectionCategorySchema,
	EditionType,
	EditionTypeSchema,
	type UploadType,
} from "@/lib/types";
import { type SubmissionResult, getFormProps, useForm } from "@conform-to/react";
import { parseWithZod } from "@conform-to/zod";
import { useRouter, useSearchParams } from "next/navigation";
import { useActionState, useCallback, useEffect, useState } from "react";
import { useFormState } from "react-dom";
import { z } from "zod";
import { StepContent } from "./StepContent";
import { StepProgress } from "./StepProgress";
import { PhotosForm } from "./UploadForms/PhotosForm";
import { UploadCollection } from "./UploadForms/UploadCollection";

// TODO: // Get all groups from Pinata

type Step = {
	current: number;
	isValid: boolean;
	data: Partial<UploadFormType>;
};

const singlePhotoSchema = z.object({
	name: z.string().min(1, "Name is required").max(100),
	description: z.string().max(1000),
	editionType: EditionTypeSchema,
	editionSize: z.coerce.number().min(1, "Edition size must be at least 1"),
	price: z.coerce.number().min(0, "Price must be positive"),
	photo: z.any().refine((val) => val instanceof File || !val, {
		message: "Photo must be a file",
	}),
	category: z.array(CollectionCategorySchema),
	groupId: z.string().optional(),
	cameraData: z
		.object({
			cameraMake: z.string().min(1, "Camera make is required").max(100).optional(),
			cameraModel: z.string().min(1, "Camera model is required").max(100).optional(),
			lens: z.string().min(1, "Lens is required").max(100).optional(),
			focalLength: z.string().min(1, "Focal length is required").max(100).optional(),
			shutterSpeed: z.string().min(1, "Shutter speed is required").max(100).optional(),
			aperture: z.string().min(1, "Shutter speed is required").max(100).optional(),
			iso: z.string().min(1, "ISO is required").max(100).optional(),
			orientation: z.enum(["Portrait", "Landscape"]).optional(),
		})
		.optional(),
	tags: z.array(z.string()),
});

export const UploadFormSchema = z.discriminatedUnion("type", [
	z.object({
		type: z.literal("single"),
		photos: z.array(singlePhotoSchema).min(1),
	}),

	z.object({
		type: z.literal("collection"),
		collectionName: z.string().min(1).max(100),
		collectionDescription: z.string().max(1000),
		// collectionCategories: z.array(CollectionCategorySchema).min(1),
		// coverImageURI: z.string().url(),
		// featuredPhotoURI: z.string().url(),
		photos: z.array(singlePhotoSchema).min(1),
	}),
]);

export type UploadFormType = z.infer<typeof UploadFormSchema>;

function isSinglePhotoForm(
	form: UploadFormType,
): form is Extract<UploadFormType, { type: "single" }> {
	return form.type === "single";
}

function isCollectionForm(
	form: UploadFormType,
): form is Extract<UploadFormType, { type: "collection" }> {
	return form.type === "collection";
}

function transformPhoto(photo: any): NonNullable<UploadFormType["photos"][number]> {
	return {
		name: String(photo.name || ""),
		description: String(photo.description || ""),
		editionType: photo.editionType as "SINGLE" | "MULTIPLE",
		editionSize: Number(photo.editionSize),
		price: Number(photo.price),
		category: (photo.category || []) as ("PHOTOGRAPHY" | "ART" | "PORTRAIT" | "LANDSCAPE")[],
		tags: Array.isArray(photo.tags) ? photo.tags.map(String) : [],
		groupId: photo.groupId ? String(photo.groupId) : undefined,
		cameraData: photo.cameraData
			? {
					cameraMake: String(photo.cameraData.cameraMake || ""),
					cameraModel: String(photo.cameraData.cameraModel || ""),
					lens: String(photo.cameraData.lens || ""),
					focalLength: String(photo.cameraData.focalLength || ""),
					shutterSpeed: String(photo.cameraData.shutterSpeed || ""),
					aperture: String(photo.cameraData.aperture || ""),
					iso: String(photo.cameraData.iso || ""),
					orientation: (photo.cameraData.orientation as "Portrait" | "Landscape") || "Landscape",
				}
			: undefined,
		photo: undefined,
	};
}

const steps = ["Form", "Review", "Upload", "Mint"];

export const UploadForm = () => {
	const [isHydrated, setIsHydrated] = useState(false);

	// Add this useEffect to handle hydration
	useEffect(() => {
		setIsHydrated(true);
	}, []);
	const { storedState, updateState, clearState } = usePersistedFormState();

	const router = useRouter();
	const searchParams = useSearchParams();

	const [currentStep, setCurrentStep] = useState(() => {
		const stepParam = searchParams.get("step");
		return stepParam ? Number.parseInt(stepParam) : 0;
	});
	const [uploadType, setUploadType] = useState<UploadType>(() => {
		const type = searchParams.get("type");
		return type === "single" || type === "collection" ? type : "single";
	});
	const [isLoading, setIsLoading] = useState(false);
	const [error, setError] = useState<string | null>(null);

	const updateURL = useCallback(
		(step: number, type: UploadType) => {
			const params = new URLSearchParams(searchParams);
			params.set("step", step.toString());
			params.set("type", type);
			router.push(`?${params.toString()}`, { scroll: false });
		},
		[router, searchParams],
	);

	const handleSubmit = async (
		prevState: unknown,
		formData: FormData,
	): Promise<SubmissionResult<string[]>> => {
		// event.preventDefault();
		setError(null);
		setIsLoading(true);

		const submission = parseWithZod(formData, {
			schema: UploadFormSchema,
		});

		try {
			if (!form.valid) throw new Error("Form is invalid");

			const formData = new FormData();
			formData.append("type", uploadType);

			if (uploadType === "single") {
				const { photos } = form.getFieldset();
				const photosList = photos.getFieldList();

				for (const [idx, photo] of photosList.entries()) {
					const photoData = photo.getFieldset();

					const photoFile = photoData.photo.value as File;

					if (photoFile) {
						formData.append("photos", photoFile);
					}

					formData.append(
						`photoMetadata[${idx}]`,
						JSON.stringify({
							name: photoData.name.value,
							description: photoData.description.value,
							editionType: photoData.editionType.value,
							editionSize: photoData.editionSize.value,
							price: photoData.price.value,
							tags: photoData.tags.value,
							cameraData: photoData.cameraData.value,
							groupId: photoData.groupId?.value,
						}),
					);
				}
			} else {
				const { photos, ...collectionData } = form.getFieldset();
				const photosList = photos.getFieldList();

				// Handle collection metadata
				formData.append(
					"collectionMetadata",
					JSON.stringify({
						collectionName: collectionData.collectionName?.value,
						collectionDescription: collectionData.collectionDescription?.value,
						collectionCategories: collectionData.collectionCategories?.value,
						coverImageURI: collectionData.coverImageURI?.value,
						featuredPhotoURI: collectionData.featuredPhotoURI?.value,
					}),
				);

				// handle the photos
				for (const [idx, photo] of photosList.entries()) {
					const photoData = photo.getFieldset();
					const photoFile = photoData.photo.value as File;
					if (photoFile) {
						formData.append(`photos[${idx}]`, photoFile);
					}

					formData.append(
						`photoMetadata[${idx}]`,
						JSON.stringify({
							name: photoData.name.value,
							description: photoData.description.value,
							editionType: photoData.editionType.value,
							editionSize: photoData.editionSize.value,
							price: photoData.price.value,
							tags: photoData.tags.value,
							cameraData: photoData.cameraData.value,
							groupId: photoData.groupId?.value,
						}),
					);
				}
			}

			// if (!isStepValid(currentStep)) {
			// 	throw new Error("Current step is invalid");
			// }

			// // Handle the submission
			// await submitForm(formData); // Your submission function

			console.log("form data here", formData);
			handleNextStep();

			return {
				status: "success",
				// data: [] // or whatever data you want to return
			};
		} catch (error) {
			const errorMessage = error instanceof Error ? error.message : "An error occurred";
			setError(errorMessage);
			console.error(error);

			return {
				status: "error",
				error: [errorMessage],
			};
		} finally {
			setIsLoading(false);
		}
	};

	const [lastResult, action] = useActionState(handleSubmit, undefined);
	const [form, fields] = useForm<UploadFormType>({
		id: "upload-form",
		lastResult,
		defaultValue: isHydrated
			? (storedState.formData ?? {
					type: uploadType,
					...(uploadType === "single"
						? {
								photos: [
									{
										name: "",
										description: "",
										editionType: EditionType.Single,
										editionSize: 1,
										price: 0,
										groupId: "",
										photo: undefined,
										category: [], // Add this
										tags: [],
										cameraData: {
											cameraMake: "",
											cameraModel: "",
											lens: "",
											focalLength: "",
											aperture: "",
											shutterSpeed: "",
											iso: "",
											orientation: "Landscape",
										},
									},
								],
							}
						: {
								collectionName: "",
								collectionDescription: "",
								collectionCategories: [],
								coverImageURI: "",
								featuredPhotoURI: "",
								photos: [
									{
										name: "",
										description: "",
										editionType: EditionType.Single,
										editionSize: 1,
										price: 0,
										groupId: "",
										photo: undefined,
										category: [], // Add this
										tags: [],
										cameraData: {
											cameraMake: "",
											cameraModel: "",
											lens: "",
											focalLength: "",
											aperture: "",
											shutterSpeed: "",
											iso: "",
											orientation: "Landscape",
										},
									},
								],
							}),
				})
			: {
					type: uploadType,
					photos: [
						{
							name: "",
							description: "",
							editionType: EditionType.Single,
							editionSize: 1,
							price: 0,
							groupId: "",
							photo: undefined,
							category: [],
							tags: [],
							cameraData: {
								cameraMake: "",
								cameraModel: "",
								lens: "",
								focalLength: "",
								aperture: "",
								shutterSpeed: "",
								iso: "",
								orientation: "Landscape",
							},
						},
					],
				},

		onValidate({ formData }) {
			return parseWithZod(formData, {
				schema: UploadFormSchema as any,
			});
		},
		shouldValidate: "onSubmit",
		shouldRevalidate: "onInput",
	});

	const handleNextStep = useCallback(() => {
		const nextStep = currentStep + 1;

		if (nextStep >= steps.length) return;

		// Optional: Add explicit validation if needed
		form.validate();
		if (!form.valid) return;

		const formValue = form.value;
		if (!formValue || typeof formValue.photos === "string") return;

		try {
			const processedFormData = {
				...formValue,
				photos: formValue.photos?.map(transformPhoto),
			} as UploadFormType;

			updateState({
				formData: processedFormData,
			});

			setCurrentStep(nextStep);
			updateURL(nextStep, uploadType);
		} catch (error) {
			console.error("Error processing form data:", error);
		}
	}, [currentStep, form, updateState, updateURL, uploadType]);

	const handlePreviousStep = useCallback(() => {
		if (currentStep <= 0) return;
		const prevStep = currentStep - 1;

		try {
			if (storedState.formData) {
				const processedFormData = {
					type: storedState.formData.type, // Ensure type is set first
					...(storedState.formData.type === "collection"
						? {
								collectionName: storedState.formData.collectionName || "",
								collectionDescription: storedState.formData.collectionDescription || "",
								collectionCategories: storedState.formData.collectionCategories || [],
								coverImageURI: storedState.formData.coverImageURI || "",
								featuredPhotoURI: storedState.formData.featuredPhotoURI || "",
							}
						: {}),
					photos:
						storedState.formData.photos?.map((photo) => ({
							...photo,
							editionType: photo.editionType || EditionType.Single,
							editionSize: Number(photo.editionSize) || 1,
							price: Number(photo.price) || 0,
							tags: Array.isArray(photo.tags) ? photo.tags : [],
							category: Array.isArray(photo.category) ? photo.category : [],
						})) || [],
				};

				form.update({
					value: processedFormData,
				});
			}
			setCurrentStep(prevStep);
			updateURL(prevStep, uploadType);
		} catch (error) {
			console.error("Error processing form data:", error);
		}
	}, [currentStep, updateURL]);

	// Handle form type changes
	const handleUploadTypeChange = useCallback(
		(value: UploadType) => {
			clearState(); // Clear stored state
			setUploadType(value);
			setCurrentStep(0); // Reset to first step
			updateURL(0, value);
			form.reset();
		},
		[clearState, form, updateURL],
	);

	useEffect(() => {
		if (form.dirty && form.value && !form.allErrors) {
			const timer = setTimeout(() => {
				const formValue = form.value;
				const isCollection = formValue?.type === "collection";

				if (!formValue?.type || !Array.isArray(formValue.photos)) return;

				const processedPhotos = formValue.photos.map(transformPhoto);

				// Create the processed form data based on type
				const processedFormData = isCollection
					? {
							type: "collection" as const,
							photos: processedPhotos,
							collectionName: (formValue as typeof formValue & { collectionName: string })
								.collectionName,
							collectionDescription: (
								formValue as typeof formValue & {
									collectionDescription: string;
								}
							).collectionDescription,
							collectionCategories: (
								formValue as typeof formValue & {
									collectionCategories: string[];
								}
							).collectionCategories,
							coverImageURI: (formValue as typeof formValue & { coverImageURI: string })
								.coverImageURI,
							featuredPhotoURI: (formValue as typeof formValue & { featuredPhotoURI: string })
								.featuredPhotoURI,
						}
					: {
							type: "single" as const,
							photos: processedPhotos,
						};

				updateState({
					formData: processedFormData,
				});
			}, 500);

			return () => clearTimeout(timer);
		}
	}, [form.dirty, form.value, form.allErrors, updateState]);

	// Reset to initial state
	const initialState = {
		type: uploadType,
		...(uploadType === "single"
			? {
					photos: [
						{
							name: "",
							description: "",
							editionType: EditionType.Single,
							editionSize: 1,
							price: 0,
							groupId: "",
							photo: undefined,
							category: [],
							tags: [],
							cameraData: {
								cameraMake: "",
								cameraModel: "",
								lens: "",
								focalLength: "",
								aperture: "",
								shutterSpeed: "",
								iso: "",
								orientation: "Landscape",
							},
						},
					],
				}
			: {
					collectionName: "",
					collectionDescription: "",
					collectionCategories: [],
					coverImageURI: "",
					featuredPhotoURI: "",
					photos: [
						{
							name: "",
							description: "",
							editionType: EditionType.Single,
							editionSize: 1,
							price: 0,
							groupId: "",
							photo: undefined,
							category: [],
							tags: [],
							cameraData: {
								cameraMake: "",
								cameraModel: "",
								lens: "",
								focalLength: "",
								aperture: "",
								shutterSpeed: "",
								iso: "",
								orientation: "Landscape",
							},
						},
					],
				}),
	};

	const handleClearForm = useCallback(() => {
		clearState(); // Clear localStorage
		form.reset(); // Reset form state

		// Reset current step and URL
		setCurrentStep(0);
		updateURL(0, uploadType);

		// Optional: Force a page refresh if needed
		// window.location.reload();
	}, [clearState, form, uploadType, updateURL]);

	// Add a loading state display
	if (!isHydrated) {
		return (
			<Card className="relative flex flex-col items-center w-full mx-auto rounded-none">
				<CardContent className="pt-6 w-full max-w-6xl">
					<div className="animate-pulse">
						{/* Add skeleton loading UI here */}
						<div className="h-4 bg-gray-200 rounded w-1/4 mb-4" />
						<div className="h-32 bg-gray-200 rounded mb-4" />
					</div>
				</CardContent>
			</Card>
		);
	}

	return (
		<Card className="relative flex flex-col items-center w-full mx-auto rounded-none">
			<CardContent className="pt-6 w-full max-w-6xl">
				<div className="mt-5">
					<StepProgress steps={steps} currentStep={currentStep} />
				</div>
				<form action={action} onSubmit={form.onSubmit} id={form.id} className="mt-5 space-y-4">
					<RadioGroup
						defaultValue={uploadType}
						onValueChange={handleUploadTypeChange}
						className="flex justify-between items-center w-full max-w-sm "
					>
						<div className="flex items-center space-x-2">
							<RadioGroupItem value="single" id="single" />
							<Label htmlFor="single">Single Photo</Label>
						</div>

						<div className="flex items-center space-x-2">
							<RadioGroupItem value="collection" id="collection" />
							<Label htmlFor="collection">Collection</Label>
						</div>
					</RadioGroup>
					{/* Steps */}
					<StepContent
						currentStep={currentStep}
						form={form}
						fields={fields}
						uploadType={uploadType}
					/>

					{/* Navigation Buttons */}
					<div className="flex justify-between mt-4">
						{currentStep > 0 && (
							<Button type="button" onClick={handlePreviousStep} className="rounded-none">
								Previous
							</Button>
						)}
						{currentStep < steps.length - 1 ? (
							<>
								<Button
									type="button"
									onClick={handleNextStep}
									className="rounded-none"
									disabled={!form.valid}
								>
									Next
								</Button>
							</>
						) : (
							<Button type="submit" className="rounded-none" disabled={!form.valid}>
								Submit
							</Button>
						)}
						{currentStep === 0 && (
							<Button
								type="button"
								onClick={handleClearForm}
								className="rounded-none  border border-destructive text-destructive hover:bg-destructive hover:text-destructive-foreground"
								{
									// Update form with initial state
									...form.reset.getButtonProps({
										name: fields.photos.name,
									})
								}
							>
								clear
							</Button>
						)}
					</div>
				</form>
			</CardContent>
		</Card>
	);
};
