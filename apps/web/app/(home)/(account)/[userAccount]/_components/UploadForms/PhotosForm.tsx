import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { usePersistedFormState } from "@/hooks/usePersistedFormState";
import { EditionType, EditionTypeSchema, type UploadType } from "@/lib/types";
import { getTagSuggestions, isValidTag, sanitizeTags } from "@/lib/utils";
import type { FormMetadata, useForm } from "@conform-to/react";
import { parseWithZod } from "@conform-to/zod";
import { EditIcon, ImagePlus } from "lucide-react";
import { type FormEvent, useEffect, useState } from "react";
import { z } from "zod";
import { LocalSelect, LocalTextArea } from ".";
import type { SinglePhotoSchema, UploadFormData } from "../UploadForm";
import { Field, FieldError } from "./ui/Fields";
import { LocalInput } from "./ui/LocalInput";

// Then modify your PhotosForm props type
interface PhotosFormProps {
	form: ReturnType<typeof useForm<UploadFormData>>[0];
	fields: ReturnType<typeof useForm<UploadFormData>>[1];
	type: UploadType;
}

export const PhotosForm = ({ form, fields }: PhotosFormProps) => {
	const [tagInput, setTagInput] = useState("");
	const photoList = fields.photos.getFieldList();

	console.log(form.allErrors);

	const getTags = (photo: ReturnType<typeof fields.photos.getFieldList>[number]): string[] => {
		const tagsValue = photo.getFieldset().tags?.value;
		if (!Array.isArray(tagsValue)) return [];
		return tagsValue.filter((tag): tag is string => typeof tag === "string");
	};

	const handleAddTag = (
		photo: ReturnType<typeof fields.photos.getFieldList>[number],
		tag: string,
	) => {
		const newTag = sanitizeTags(tagInput);

		console.log("here", newTag);

		if (!newTag || !isValidTag(newTag)) return;

		const currentTags = getTags(photo);

		if (currentTags.length >= 10) return;
		if (currentTags.includes(newTag)) return;

		const updatedTags = [...currentTags, newTag];
		photo.getFieldset().tags.value = updatedTags;

		form.validate();
		setTagInput("");
	};

	const removeTag = (
		photo: ReturnType<typeof fields.photos.getFieldList>[number],
		tagToRemove: string,
	) => {
		const currentTags = Array.isArray(photo.getFieldset().tags.value)
			? photo.getFieldset().tags.value
			: [];

		if (!currentTags) return;

		if (!currentTags.includes(tagToRemove)) return;

		if (typeof currentTags === "string") {
			photo.getFieldset().tags.value = [];
			form.validate();
			return;
		}

		const updatedTags = currentTags.filter((tag) => tag !== tagToRemove);

		photo.getFieldset().tags.value = updatedTags;
		form.validate();
	};

	return (
		<div className="space-y-6">
			{photoList.map((photo, index) => (
				<div
					key={photo.id}
					className="relative p-4 border rounded-none border-dotted border-amber-600/20"
				>
					{photoList.length > 1 && (
						<Button
							variant="destructive"
							size="sm"
							className="absolute top-2 right-2"
							onClick={() => form.remove(photo)}
						>
							Remove
						</Button>
					)}
					<div className="space-y-4">
						<Field>
							<Label htmlFor={photo.name}>Name</Label>
							<LocalInput
								meta={photo.getFieldset().name}
								defaultValue={photo.getFieldset().name.initialValue}
								type="text"
								className="w-full rounded-none"
							/>
							{photo.getFieldset().name.errors && (
								<FieldError>{photo.getFieldset().name.errors}</FieldError>
							)}
						</Field>

						<Field>
							<Label htmlFor={photo.getFieldset().description.name}>Description</Label>
							<LocalTextArea
								className="w-full rounded-none"
								meta={photo.getFieldset().description}
								defaultValue={photo.getFieldset().description.initialValue}
							/>
							{photo.getFieldset().description.errors && (
								<FieldError>{photo.getFieldset().description.errors}</FieldError>
							)}
						</Field>

						<div className="flex justify-between gap-3 max-w-2xl">
							<Field>
								<Label htmlFor={photo.getFieldset().editionType.name}>Edition Type</Label>
								<LocalSelect
									placeholder="Edition type"
									meta={photo.getFieldset().editionType}
									defaultValue={photo.getFieldset().editionType.initialValue}
									items={[
										{ value: EditionType.Single, name: "Single" },
										{ value: EditionType.Multiple, name: "Multiple" },
									]}
									// className="rounded-none bg-white dark:bg-black"
								/>
								{photo.getFieldset().editionType.errors && (
									<FieldError>{photo.getFieldset().editionType.errors}</FieldError>
								)}
							</Field>

							<Field>
								<Label htmlFor={photo.getFieldset().editionSize.name}>Edition Size</Label>
								<LocalInput
									type="number"
									min="1"
									meta={photo.getFieldset().editionSize}
									defaultValue={photo.getFieldset().editionSize.initialValue}
									className="rounded-none bg-white dark:bg-black"
								/>
								{photo.getFieldset().editionSize.errors && (
									<FieldError>{photo.getFieldset().editionSize.errors}</FieldError>
								)}
							</Field>

							<Field>
								<Label htmlFor={photo.getFieldset().price.name}>Price</Label>
								<LocalInput
									type="number"
									min="0"
									step="0.01"
									meta={photo.getFieldset().price}
									defaultValue={photo.getFieldset().price.initialValue}
									className="rounded-none bg-white dark:bg-black"
								/>
								{photo.getFieldset().price.errors && (
									<FieldError>{photo.getFieldset().price.errors}</FieldError>
								)}
							</Field>
						</div>

						<Field>
							<div className="border-2 border-dashed border-border rounded-none p-8 text-center">
								<LocalInput
									type="file"
									accept="image/*"
									meta={photo.getFieldset().photo}
									className="hidden"
									id={photo.getFieldset().photo.id}
									// defaultValue={photo.getFieldset().photo}
								/>
								<Label
									htmlFor={photo.getFieldset().photo.name}
									className="cursor-pointer flex flex-col items-center"
								>
									<ImagePlus className="h-12 w-12 text-muted-foreground" />
								</Label>

								{photo.getFieldset().photo.errors && (
									<FieldError>{photo.getFieldset().photo.errors}</FieldError>
								)}
							</div>
						</Field>

						<Field>
							<Label htmlFor={photo.getFieldset().groupId.name}>Group ID</Label>
							<LocalInput
								meta={photo.getFieldset().groupId}
								type="text"
								className="w-full rounded-none"
								placeholder="Optional group identifier"
								defaultValue={photo.getFieldset().groupId.initialValue}
							/>
							{photo.getFieldset().groupId.errors && (
								<FieldError>{photo.getFieldset().groupId.errors}</FieldError>
							)}
						</Field>

						<Field>
							<Label htmlFor={photo.getFieldset().tags.name}>Tags</Label>
							<div className="space-y-2">
								<LocalInput
									meta={photo.getFieldset().tags}
									type="text"
									value={tagInput}
									onChange={(e) => setTagInput(e.target.value)}
									onKeyDown={(e) => {
										if (e.key === "Enter") {
											e.preventDefault();
											handleAddTag(photo, tagInput);
										}
									}}
									placeholder="Press enter to add tags"
									className="w-full rounded-none"
								/>
								<div className="flex flex-wrap gap-2">
									{getTags(photo).map((tag) => (
										<Badge key={tag} variant="secondary" className="px-2 py-1">
											{tag}
											<button
												type="button"
												onClick={() => removeTag(photo, tag)}
												className="ml-2 hover:text-destructive"
											>
												×
											</button>
										</Badge>
									))}
								</div>
								{tagInput.length > 0 && (
									<div className="absolute z-10 w-fit bg-white dark:bg-black border border-border rounded-none shadow-lg">
										{getTagSuggestions(tagInput, getTags(photo)).map((suggestion) => (
											<button
												key={suggestion}
												type="button"
												className="w-full px-4 py-2 text-left hover:bg-muted"
												onClick={() => handleAddTag(photo, suggestion)}
											>
												{suggestion}
											</button>
										))}
									</div>
								)}
							</div>
							{photo.getFieldset().tags.errors && (
								<FieldError>{photo.getFieldset().tags.errors}</FieldError>
							)}
						</Field>

						{/* Camera Data */}
						<div className="space-y-4 border border-border p-4 mt-4">
							<h3 className="font-normal">Camera Information</h3>
							<div className="grid grid-cols-2 gap-4">
								<Field>
									<Label htmlFor={photo.getFieldset().cameraData.getFieldset().cameraMake.name}>
										Camera Make
									</Label>
									<LocalInput
										meta={photo.getFieldset().cameraData.getFieldset().cameraMake}
										type="text"
										className="w-full rounded-none"
										placeholder="e.g., Canon, Nikon"
										defaultValue={
											photo.getFieldset().cameraData.getFieldset().cameraMake.initialValue
										}
									/>
									{photo.getFieldset().cameraData.getFieldset().cameraMake.errors && (
										<FieldError>
											{photo.getFieldset().cameraData.getFieldset().cameraMake.errors}
										</FieldError>
									)}
								</Field>

								<Field>
									<Label htmlFor={photo.getFieldset().cameraData.getFieldset().cameraModel.id}>
										Camera Model
									</Label>
									<LocalInput
										meta={photo.getFieldset().cameraData.getFieldset().cameraModel}
										type="text"
										className="w-full rounded-none"
										placeholder="e.g., EOS R5, Z6"
										defaultValue={
											photo.getFieldset().cameraData.getFieldset().cameraModel.initialValue
										}
									/>
									{photo.getFieldset().cameraData.getFieldset().cameraModel.errors && (
										<FieldError>{fields.cameraData.getFieldset().cameraModel.errors}</FieldError>
									)}
								</Field>

								<Field>
									<Label htmlFor={photo.getFieldset().cameraData.getFieldset().lens.id}>Lens</Label>
									<LocalInput
										meta={photo.getFieldset().cameraData.getFieldset().lens}
										defaultValue={photo.getFieldset().cameraData.getFieldset().lens.initialValue}
										type="text"
										className="w-full rounded-none"
										placeholder="e.g., 24-70mm f/2.8"
									/>
									{photo.getFieldset().cameraData.getFieldset().lens.errors && (
										<FieldError>
											{photo.getFieldset().cameraData.getFieldset().lens.errors}
										</FieldError>
									)}
								</Field>

								<Field>
									<Label htmlFor={photo.getFieldset().cameraData.getFieldset().shutterSpeed.id}>
										Shutter Speed
									</Label>
									<LocalInput
										meta={photo.getFieldset().cameraData.getFieldset().shutterSpeed}
										defaultValue={
											photo.getFieldset().cameraData.getFieldset().shutterSpeed.initialValue
										}
										type="text"
										className="w-full rounded-none"
										placeholder="e.g., 1/1000"
									/>
									{photo.getFieldset().cameraData.getFieldset().shutterSpeed.errors && (
										<FieldError>
											{photo.getFieldset().cameraData.getFieldset().shutterSpeed.errors}
										</FieldError>
									)}
								</Field>

								<Field>
									<Label htmlFor={photo.getFieldset().cameraData.getFieldset().aperture.id}>
										Aperture
									</Label>
									<LocalInput
										meta={photo.getFieldset().cameraData.getFieldset().aperture}
										defaultValue={
											photo.getFieldset().cameraData.getFieldset().aperture.initialValue
										}
										type="text"
										className="w-full rounded-none"
										placeholder="e.g., f/2.8"
									/>
									{photo.getFieldset().cameraData.getFieldset().aperture.errors && (
										<FieldError>
											{photo.getFieldset().cameraData.getFieldset().aperture.errors}
										</FieldError>
									)}
								</Field>
							</div>
						</div>
					</div>
				</div>
			))}
			<Button
				onClick={() => {
					form.validate();
					const hasErrors = Object.keys(form.allErrors).length > 0;
					if (!hasErrors) {
						form.insert({
							photos: {
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
						});
					}
				}}
				className="w-full rounded-none"
				disabled={!form.valid}
			>
				{Object.keys(form.allErrors ?? {}).length > 0
					? "Please fix form errors before adding another photo"
					: "Add Another Photo"}
			</Button>
		</div>
	);
};
