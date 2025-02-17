"use client";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { Progress } from "@/components/ui/progress";
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import { usePersistedFormState } from "@/hooks/usePersistedFormState";
import {
	CollectionCategorySchema,
	EditionType,
	EditionTypeSchema,
	type UploadType,
} from "@/lib/types";
import { useForm } from "@conform-to/react";
import { parseWithZod } from "@conform-to/zod";
import { useRouter, useSearchParams } from "next/navigation";
import { type FormEvent, useActionState, useEffect, useState } from "react";
import { useFormState } from "react-dom";
import { z } from "zod";
import { PhotosForm } from "./UploadForms/PhotosForm";
import { UploadCollection } from "./UploadForms/UploadCollection";

// TODO: // Get all groups from Pinata

const PhotoSchema = z.object({
	editionType: EditionTypeSchema,
	category: CollectionCategorySchema,
});

const singlePhotoSchema = z.object({
	name: z.string().min(1, "Name is required").max(100),
	description: z.string().max(1000),
	editionType: EditionTypeSchema,
	editionSize: z.coerce.number().min(1, "Edition size must be at least 1"),
	price: z.coerce.number().min(0, "Price must be positive"),
	photo: z.instanceof(File).optional(),
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

export type SinglePhotoSchema = z.infer<typeof singlePhotoSchema>;

// Collection Metadata Schema
const CollectionMetadataSchema = z.object({
	coverImageURI: z.string().url(),
	featuredPhotoURI: z.string().url(),
	tags: z.array(z.string()),
});

// Collection Upload Schema
const collectionUploadSchema = z.object({
	// type: z.literal("collection"),
	collectionName: z.string().min(1).max(100),
	collectionDescription: z.string().max(1000),
	collectionCategories: z.array(CollectionCategorySchema).min(1),
	collectionTags: z.array(z.string()),
	coverImageURI: z.string().url(),
	featuredPhotoURI: z.string().url(),
	photos: z.array(singlePhotoSchema).min(1),
});

export type CollectionUploadSchema = z.infer<typeof collectionUploadSchema>;

const uploadSchema = z.discriminatedUnion("type", [
	// Single Photo(s) Schema
	z.object({
		type: z.literal("single"),
		photos: z.array(singlePhotoSchema).min(1),
	}),

	// Collection Schema
	collectionUploadSchema.extend({
		type: z.literal("collection"),
	}),
]);

// Create a type from the schema
export type UploadFormData = z.infer<typeof uploadSchema>;

const steps = ["Form", "Review", "Upload", "Mint"];

export const UploadForm = () => {
	const { storedState, updateState, clearState } = usePersistedFormState();

	const router = useRouter();
	const searchParams = useSearchParams();

	const [currentStep, setCurrentStep] = useState(0);
	const [uploadType, setUploadType] = useState<UploadType>(() => {
		const type = searchParams.get("type");
		return type === "single" || type === "collection" ? type : "single";
	});

	const handleUploadTypeChange = (value: UploadType) => {
		setUploadType(value);
		const params = new URLSearchParams(searchParams);
		params.set("type", value);

		// Update URL without reload
		router.push(`?${params.toString()}`, { scroll: false });
	};

	const submitFormServerAction = async (_prevState: unknown, formData: FormData) => {
		const submission = parseWithZod(formData, {
			schema: uploadSchema,
		});

		console.log("submissioin", submission);

		if (submission.status !== "success") {
			return submission.reply();
		}

		// Handle successful submission
		// redirect('/dashboard')
		// setCurrentStep(2);
		console.log(submission.value);
	};

	const [lastResult] = useActionState(submitFormServerAction, undefined);
	const [form, fields] = useForm<UploadFormData>({
		id: "upload-form",
		lastResult,
		defaultValue: storedState.formData || {
			type: "single",
			photos: [
				{
					name: "",
					description: "",
					editionType: EditionType.Single,
					editionSize: 1,
					price: 0,
					photo: undefined,
					groupId: "",
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
				schema: uploadSchema,
			});
		},
		shouldValidate: "onBlur",
		shouldRevalidate: "onInput",
	});

	useEffect(() => {
		if (form.dirty && form.value && !form.allErrors) {
			const timer = setTimeout(() => {
				updateState({
					formData: {
						type: form.value?.type || ("single" as string),
						photos: form.value?.photos || [],
					},
				});
			}, 500); // Debounce updates

			return () => clearTimeout(timer);
		}
	}, [form.dirty, form.value, form.allErrors, updateState]);

	const renderStep = () => {
		switch (currentStep) {
			case 0:
				return (
					<Card className="relative flex flex-col items-center w-full mx-auto rounded-none">
						<CardContent className="pt-6 w-full max-w-6xl">
							<div className="mt-5">
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
							</div>
							<form id={form.id} onSubmit={form.onSubmit} className="mt-5 space-y-4">
								<input type="hidden" name="type" value={uploadType} />
								{uploadType === "single" && (
									<PhotosForm form={form} fields={fields} type={uploadType} />
								)}
								{uploadType === "collection" && (
									<UploadCollection form={form} fields={fields} type={uploadType} />
								)}
							</form>
							<Button
								type="submit"
								className="rounded-none"
								disabled={!form.valid}
								onClick={() => setCurrentStep(1)}
							>
								Next
							</Button>
							<Button
								type="reset"
								className="rounded-none"
								disabled={!form.valid}
								onClick={() => clearState()}
							>
								Clear
							</Button>
							d
						</CardContent>
					</Card>
				);
		}
	};

	console.log("form values", form.value);

	return (
		<Card className="relative flex flex-col items-center w-full mx-auto rounded-none">
			<CardContent className="pt-6 w-full max-w-6xl">
				<div>
					<div className="flex justify-between mb-2 max-w-4xl">
						{steps.map((step, index) => (
							<div
								key={step}
								className={`text-sm ${index === currentStep ? "text-primary" : "text-muted-foreground"}`}
							>
								{step}
							</div>
						))}
					</div>
					<Progress value={(currentStep / (steps.length - 1)) * 100} className="w-full" />
				</div>
				{renderStep()}
			</CardContent>
		</Card>
	);
};
