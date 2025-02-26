"use client";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { EditionType, type UploadType } from "@/lib/types";
import { getTagSuggestions } from "@/lib/utils";
import type { useForm } from "@conform-to/react";
import { ImagePlus } from "lucide-react";
import Image from "next/image";
import { useEffect, useState } from "react";
import { LocalSelect, LocalTextArea } from ".";
import type { UploadFormType } from "../UploadForm";
import { Field, FieldError } from "./ui/Fields";
import { LocalInput } from "./ui/LocalInput";
import { MultiSelect } from "./ui/MultiSelect";

// Then modify your PhotosForm props type
interface PhotosFormProps {
	form: ReturnType<typeof useForm<UploadFormType>>[0];
	fields: ReturnType<typeof useForm<UploadFormType>>[1];
	type: UploadType;
}

export const PhotosForm = ({ form, fields, type }: PhotosFormProps) => {
	if (!form.value) {
		return (
			<div className="space-y-6">
				<div className="animate-pulse">{/* Add skeleton loading UI here */}</div>
			</div>
		);
	}

	const photoList = fields.photos.getFieldList();

	const getTags = (photo: ReturnType<typeof fields.photos.getFieldList>[number]): string[] => {
		const tagsValue = photo.getFieldset().tags?.value;
		return Array.isArray(tagsValue) ? tagsValue.map(String) : [];
	};

	return (
		<div className="space-y-6">
			{photoList.map((photo, index) => (
				<div
					key={photo.key}
					className="relative p-4 border rounded-none border-dotted border-amber-600/20"
				>
					{photoList.length > 1 && (
						<div className="absolute top-2 right-2">
							<Button
								variant="destructive"
								size="sm"
								className="absolute top-2 right-2"
								{...form.remove.getButtonProps({
									name: fields.photos.name,
									index,
								})}
							>
								Remove
							</Button>
						</div>
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
									// value={photo.getFieldset().editionType.value === EditionType.Single && photo.getFieldset().editionSize.value = "1"}
									onChange={(e) => {
										if (photo.getFieldset().editionType.value === EditionType.Single) {
											photo.getFieldset().editionSize.value = "1";
										}
									}}
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
							<FileUploadPreview photo={photo} />
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
								<MultiSelect
									meta={photo.getFieldset().tags}
									options={Array.from(new Set(getTagSuggestions("", getTags(photo))))}
									placeholder="Select or enter tags..."
									emptyPlaceholder="No tags found. Press enter to create a new tag."
									defaultValue={getTags(photo)}
									className="w-full"
								/>
							</div>

							{photo.getFieldset().tags.errors && (
								<FieldError>{photo.getFieldset().tags.errors}</FieldError>
							)}
						</Field>

						{/* Camera Data */}
						<div className="space-y-4 border p-4 mt-4">
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
										<FieldError>
											{photo.getFieldset().cameraData.getFieldset().cameraModel.errors}
										</FieldError>
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
			<div className="w-full">
				<Button
					onClick={() => {
						form.validate();
						if (!form.valid) {
							return;
						}
					}}
					className="w-full rounded-none"
					disabled={!form.valid}
					{...form.insert.getButtonProps({
						name: fields.photos.name,
					})}
				>
					{Object.keys(form.allErrors ?? {}).length > 0
						? "Please fix form errors before adding another photo"
						: "Add Another Photo"}
				</Button>
			</div>
		</div>
	);
};

const FileUploadPreview = ({
	photo,
}: {
	photo: ReturnType<
		ReturnType<typeof useForm<UploadFormType>>[1]["photos"]["getFieldList"]
	>[number];
}) => {
	const [previewUrl, setPreviewUrl] = useState<string | null>(null);
	useEffect(() => {
		const file = photo.getFieldset().photo.value;
		if (file instanceof File) {
			const objectUrl = URL.createObjectURL(file);
			setPreviewUrl(objectUrl);

			return () => {
				URL.revokeObjectURL(objectUrl);
				setPreviewUrl(null);
			};
		}
	}, [photo.getFieldset().photo.value]);

	return (
		<div className="border-2 border-dashed rounded-none p-8 text-center">
			<LocalInput
				type="file"
				accept="image/*"
				meta={photo.getFieldset().photo}
				className="hidden"
				id={photo.getFieldset().photo.id}
			/>
			<Label
				htmlFor={photo.getFieldset().photo.id}
				className="cursor-pointer flex flex-col items-center"
			>
				{photo.getFieldset().photo.value instanceof File && previewUrl ? (
					<div className="flex flex-col items-center">
						<img src={previewUrl} alt="Preview" className="w-32 h-32 object-cover mb-2" />
						<span className="text-sm text-muted-foreground">
							{(photo.getFieldset().photo.value as File).name}
						</span>
					</div>
				) : (
					<ImagePlus className="h-12 w-12 text-muted-foreground" />
				)}
			</Label>

			{photo.getFieldset().photo.errors && (
				<FieldError>{photo.getFieldset().photo.errors}</FieldError>
			)}
		</div>
	);
};
