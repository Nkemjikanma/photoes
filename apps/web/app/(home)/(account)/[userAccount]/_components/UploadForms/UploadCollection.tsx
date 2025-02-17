import { Label } from "@/components/ui/label";
import { usePersistedFormState } from "@/hooks/usePersistedFormState";
import { CollectionCategorySchema, type UploadType } from "@/lib/types";
import type { useForm } from "@conform-to/react";
import { useState } from "react";
import type { UploadFormData } from "../UploadForm";
import { PhotosForm } from "./PhotosForm";
import { Field, FieldError } from "./ui/Fields";
import { LocalInput } from "./ui/LocalInput";
import { LocalSelect } from "./ui/LocalSelect";
import { LocalTextArea } from "./ui/LocalTextArea";

interface UploadCollectionProps {
	form: ReturnType<typeof useForm<UploadFormData>>[0];
	fields: ReturnType<typeof useForm<UploadFormData>>[1];
	type: UploadType;
}

export const UploadCollection = ({ form, fields, type }: UploadCollectionProps) => {
	return (
		<div className="space-y-4">
			{/* Collection Info */}

			<div className="relative space-y-4 p-4 border rounded-none border-amber-600/20">
				<Field>
					<Label htmlFor={fields.collectionName.id}>Collection Name</Label>
					<LocalInput meta={fields.collectionName} type="text" className="w-full rounded-none" />
					{fields.collectionName.errors && <FieldError>{fields.collectionName.errors}</FieldError>}
				</Field>

				<Field>
					<Label htmlFor={fields.collectionDescription.id}>Description</Label>
					<LocalTextArea className="w-full rounded-none" meta={fields.collectionDescription} />
					{fields.collectionDescription.errors && (
						<FieldError>{fields.collectionDescription.errors}</FieldError>
					)}
				</Field>

				<Field>
					<Label htmlFor={fields.collectionCategories.id}>Categories</Label>
					<LocalSelect
						placeholder="Categories"
						meta={fields.collectionCategories}
						items={Object.values(CollectionCategorySchema.enum).map((category) => ({
							value: category,
							name: category,
						}))}
						// className="rounded-none bg-white dark:bg-black"
					/>
				</Field>

				<Field>
					<Label htmlFor={fields.collectionTags.id}>Tags</Label>
					<LocalInput
						meta={fields.collectionTags}
						type="text"
						className="w-full rounded-none"
						placeholder="Separate tags with commas"
					/>
				</Field>

				{/*Photos */}
				<div className="mt-5 space-y-4">
					<h4 className="font-normal">Collection Photos</h4>
					<PhotosForm form={form} fields={fields} type={type} />
				</div>
			</div>
		</div>
	);
};
