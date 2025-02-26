"use client";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import { usePersistedFormState } from "@/hooks/usePersistedFormState";
import { uploadFormSchema } from "@/lib";
import { submitHandler } from "@/lib/server";
import { type CollectionCategory, EditionType, UploadType } from "@/lib/types";
import {
	FormProvider,
	FormStateInput,
	type SubmissionResult,
	getFormProps,
	useForm,
} from "@conform-to/react";
import { parseWithZod } from "@conform-to/zod";
import { useRouter, useSearchParams } from "next/navigation";
import { useActionState, useCallback, useEffect, useState } from "react";
import type { z } from "zod";
import { StepContent } from "./StepContent";
import { StepProgress } from "./StepProgress";
import {
	EmptyFormState,
	EmptyPhotoFormState,
	EmptyPhotoItemState,
	type FormPhotoInput,
} from "./utils";

// TODO: // Get all groups from Pinata

export type UploadFormType = z.infer<typeof uploadFormSchema>;

function transformPhoto(
	photo: Partial<FormPhotoInput> | undefined,
): NonNullable<UploadFormType["photos"][number]> {
	if (!photo) {
		return {
			name: "",
			description: "",
			editionType: EditionType.Single,
			editionSize: 1,
			price: 0,
			tags: [],
			photo: undefined,
			groupId: undefined,
			cameraData: undefined,
		};
	}

	return {
		name: String(photo.name || ""),
		description: String(photo.description || ""),
		editionType: photo.editionType === "MULTIPLE" ? EditionType.Multiple : EditionType.Single,
		editionSize: Number(photo.editionSize || 1),
		price: Number(photo.price || 0),
		tags: (Array.isArray(photo.category) ? photo.category : []) as CollectionCategory[],
		groupId: photo.groupId ? String(photo.groupId) : undefined,
		cameraData: {
			cameraMake: String(photo?.cameraData?.cameraMake || ""),
			cameraModel: String(photo?.cameraData?.cameraModel || ""),
			lens: String(photo?.cameraData?.lens || ""),
			focalLength: String(photo?.cameraData?.focalLength || ""),
			shutterSpeed: String(photo?.cameraData?.shutterSpeed || ""),
			aperture: String(photo?.cameraData?.aperture || ""),
			iso: String(photo?.cameraData?.iso || ""),
			orientation: (photo?.cameraData?.orientation as "Portrait" | "Landscape") || "Landscape",
		},
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
		return type === "single"
			? UploadType.Single
			: type === "collection"
				? UploadType.Collection
				: UploadType.Single;
	});

	const updateURL = useCallback(
		(step: number, type: UploadType) => {
			const params = new URLSearchParams(searchParams);
			params.set("step", step.toString());
			params.set("type", type);
			router.push(`?${params.toString()}`, { scroll: false });
		},
		[router, searchParams],
	);

	const [lastResult, action] = useActionState(submitHandler, undefined);
	const [form, fields] = useForm<UploadFormType>({
		id: "upload-form",
		lastResult,
		defaultValue: isHydrated ? (storedState.formData ?? EmptyFormState) : EmptyPhotoFormState,
		onValidate({ formData }) {
			return parseWithZod(formData, {
				schema: uploadFormSchema as any,
			});
		},
		shouldValidate: "onSubmit",
		shouldRevalidate: "onInput",
	});

	const processFormCameraData = (formValue?: FormPhotoInput[] | undefined) => {
		if (!formValue) return [];

		return formValue.map((photoItem) => {
			const cameraData =
				typeof photoItem?.cameraData === "object" ? photoItem.cameraData : undefined;

			return {
				...photoItem,
				cameraData: cameraData
					? {
							cameraMake: String(cameraData.cameraMake || ""),
							cameraModel: String(cameraData.cameraModel || ""),
							lens: String(cameraData.lens || ""),
							focalLength: String(cameraData.focalLength || ""),
							shutterSpeed: String(cameraData.shutterSpeed || ""),
							aperture: String(cameraData.aperture || ""),
							iso: String(cameraData.iso || ""),
							orientation: cameraData.orientation || "Landscape",
						}
					: undefined,
			};
		});
	};

	const handleNextStep = useCallback(() => {
		if (!form.valid) return;

		const formValue = form.value;
		if (!formValue || !Array.isArray(formValue.photos)) return;

		try {
			const processedPhotos = processFormCameraData(formValue.photos as FormPhotoInput[]);

			const processedFormData = {
				...formValue,
				photos: processedPhotos.map(transformPhoto),
			} as UploadFormType;

			// const processedFormData = {
			// 	type: formValue.type,
			// 	...(formValue.type === "collection"
			// 		? {
			// 				collectionName: formValue.collectionName,
			// 				collectionDescription: formValue.collectionDescription,
			// 			}
			// 		: {}),
			// 	photos: processedPhotos.map(transformPhoto),
			// } as UploadFormType;

			updateState({
				formData: processedFormData,
			});

			// // Update form value
			form.update({
				value: processedFormData,
			});
			const nextStep = currentStep + 1;
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
							}
						: {}),
					photos:
						storedState.formData.photos?.map((photo) => ({
							...photo,
							editionType: photo.editionType || EditionType.Single,
							editionSize: Number(photo.editionSize) || 1,
							price: Number(photo.price) || 0,
							tags: Array.isArray(photo.tags) ? photo.tags : [],
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
	}, [currentStep, form, storedState.formData, updateURL, uploadType]);

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
				const formValue = form.value as Partial<UploadFormType>;
				const isCollection = formValue?.type === "collection";

				if (!formValue?.type || !Array.isArray(formValue.photos)) return;

				const processedCameraData = processFormCameraData(formValue.photos as FormPhotoInput[]);

				// Process the photos correctly
				const processedPhotos = processedCameraData.map(transformPhoto);

				// const processedPhotos = formValue.photos.map(transformPhoto);

				// Create the processed form data based on type
				const processedFormData = isCollection
					? {
							type: "collection" as const,
							photos: processedPhotos,
							collectionName: formValue.collectionName,
							collectionDescription: formValue?.collectionDescription,
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
	}, [form, updateState]);

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

	console.log("form", form.errorId);
	console.log("all errors", form.allErrors);

	return (
		<Card className="relative flex flex-col items-center w-full mx-auto rounded-none">
			<CardContent className="pt-6 w-full max-w-6xl">
				<div className="mt-5">
					<StepProgress steps={steps} currentStep={currentStep} />
				</div>
				<FormProvider context={form.context}>
					<FormStateInput />
					<form action={action} onSubmit={form.onSubmit} id={form.id} className="mt-5 space-y-4">
						<RadioGroup
							defaultValue={uploadType}
							onValueChange={(value: string) => handleUploadTypeChange(value as UploadType)}
							className="flex justify-between items-center w-full max-w-sm "
						>
							<div className="flex items-center space-x-2">
								<RadioGroupItem value={UploadType.Single} id="single" />
								<Label htmlFor="single">Single Photo</Label>
							</div>

							<div className="flex items-center space-x-2">
								<RadioGroupItem value={UploadType.Collection} id="collection" />
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
								<Button
									type="submit"
									onClick={handlePreviousStep}
									className="rounded-none"
									// value="previous"
									// name="intent"
								>
									Previous
								</Button>
							)}
							{currentStep === 0 ? (
								<>
									<Button
										type="button"
										// name="intent"
										className="rounded-none"
										disabled={!form.valid}
										// value="next"
										onClick={handleNextStep}
									>
										Next
									</Button>
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
										value="clear"
										name="intent"
									>
										clear
									</Button>
								</>
							) : (
								<Button type="submit" className="rounded-none" disabled={!form.valid}>
									Submit
								</Button>
							)}
						</div>
					</form>
				</FormProvider>
			</CardContent>
		</Card>
	);
};
