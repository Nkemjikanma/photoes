import { Badge } from "@/components/ui/badge";
import { Card } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { usePersistedFormState } from "@/hooks/usePersistedFormState";
import type { UploadType } from "@/lib/types";
import { type FormId, FormStateInput, use, useFormMetadata } from "@conform-to/react";
import { useEffect, useState } from "react";
import type { UploadFormType } from "../UploadForm";
import { LocalInput } from "./ui/LocalInput";

interface ReviewStepProps {
	formId: FormId;
	uploadType: UploadType;
}

export const ReviewStep = ({ formId, uploadType }: ReviewStepProps) => {
	const form = useFormMetadata(formId);

	console.log("review step count -", form.getFieldset());

	// Add this effect to ensure form data is loaded
	// useEffect(() => {
	// 	if (storedState.formData) {
	// 		form.update({
	// 			value: storedState.formData,
	// 		});
	// 	}
	// }, [storedState.formData, form]);

	const formValues = form.value;

	const isCollection = uploadType === "collection";

	console.log("form review", form.value);

	const getTags = (tags: unknown): string[] => {
		if (Array.isArray(tags)) return tags;
		if (typeof tags === "string") {
			try {
				const parsed = JSON.parse(tags);
				return Array.isArray(parsed) ? parsed : [];
			} catch {
				return [];
			}
		}
		return [];
	};

	// if (
	// 	!formValues ||
	// 	!formValues.photos ||
	// 	!formValues.photos.length ||
	// 	typeof formValues.photos === "string"
	// )
	// 	return <div>No form data available</div>;

	console.log("yellooo", formValues);

	return (
		<>
			<FormStateInput />
			<FormStateDebug formId={formId} />
			{}
		</>
		// <div className="space-y-8">
		// 	{/* Collection Info (if applicable) */}
		// 	{uploadType === "collection" && (
		// 		<Card className="p-6">
		// 			<h3 className="text-lg font-semibold mb-4">Collection Information</h3>
		// 			<div className="space-y-4">
		// 				<div>
		// 					<Label>Collection Name</Label>
		// 					<p>{formValues?.collectionName}</p>
		// 				</div>
		// 				<div>
		// 					<Label>Description</Label>
		// 					<p>{formValues.collectionDescription}</p>
		// 				</div>
		// 			</div>
		// 		</Card>
		// 	)}

		// 	{/* Photos Review */}
		// 	<div className="space-y-6">
		// 		<h3 className="text-lg font-semibold">Photos</h3>
		// 		{formValues.photos.map((photo, index) => (
		// 			<Card key={index} className="p-6">
		// 				<div className="grid md:grid-cols-2 gap-6">
		// 					{/* Photo Preview */}
		// 					{photo.photo instanceof File && (
		// 						<div className="aspect-square bg-muted rounded-lg">
		// 							<img
		// 								src={URL.createObjectURL(photo.photo)}
		// 								alt={photo.name}
		// 								className="object-cover w-full h-full rounded-lg"
		// 							/>
		// 						</div>
		// 					)}

		// 					{/* Photo Details */}
		// 					<div className="space-y-4">
		// 						<div>
		// 							<Label>Name</Label>
		// 							<p>{photo.name}</p>
		// 						</div>
		// 						<div>
		// 							<Label>Description</Label>
		// 							<p>{photo.description}</p>
		// 						</div>
		// 						<div className="grid grid-cols-2 gap-4">
		// 							<div>
		// 								<Label>Edition Type</Label>
		// 								<p>{photo.editionType}</p>
		// 							</div>
		// 							<div>
		// 								<Label>Edition Size</Label>
		// 								<p>{photo.editionSize}</p>
		// 							</div>
		// 							<div>
		// 								<Label>Price</Label>
		// 								<p>${photo.price}</p>
		// 							</div>
		// 						</div>
		// 						{photo.cameraData && (
		// 							<div>
		// 								<Label>Camera Information</Label>
		// 								<div className="grid grid-cols-2 gap-2 mt-2 text-sm">
		// 									<p>Make: {photo.cameraData.cameraMake}</p>
		// 									<p>Model: {photo.cameraData.cameraModel}</p>
		// 									<p>Lens: {photo.cameraData.lens}</p>
		// 									<p>Shutter Speed: {photo.cameraData.shutterSpeed}</p>
		// 									<p>Aperture: {photo.cameraData.aperture}</p>
		// 								</div>
		// 							</div>
		// 						)}
		// 					</div>
		// 				</div>
		// 			</Card>
		// 		))}
		// 	</div>
		// </div>
	);
};

const FormStateDebug = ({ formId }: { formId: string }) => {
	const form = useFormMetadata(formId);

	return <pre className="text-xs">{JSON.stringify(form.value, null, 2)}</pre>;
};
