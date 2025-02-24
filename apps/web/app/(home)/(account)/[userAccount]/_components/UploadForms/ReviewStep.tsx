"use client";

import { Badge } from "@/components/ui/badge";
import { Card } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import type { UploadType } from "@/lib/types";
import type { useForm } from "@conform-to/react";
import type { UploadFormType } from "../UploadForm";

interface ReviewStepProps {
	form: ReturnType<typeof useForm<UploadFormType>>[0];
	fields: ReturnType<typeof useForm<UploadFormType>>[1];
	uploadType: UploadType;
}

export const ReviewStep = ({ form, fields, uploadType }: ReviewStepProps) => {
	const photoList = fields.photos.getFieldList();
	const isCollection = uploadType === "collection";

	console.log(
		"review step",
		photoList.map((photo) => photo.getFieldset().name),
	);

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

	console.log("collection", form.allErrors);

	return (
		<div className="space-y-8">
			{/* Collection Info (if applicable) */}
			{isCollection && (
				<Card className="p-6">
					<h3 className="text-lg font-semibold mb-4">Collection Information</h3>
					<div className="space-y-4">
						<div>
							<label className="text-sm font-medium">Collection Name</label>
							<p>{fields.collectionName?.value}</p>
						</div>
						<div>
							<label className="text-sm font-medium">Description</label>
							<p className="text-sm text-muted-foreground">{fields.collectionDescription?.value}</p>
						</div>
						<div>
							<label className="text-sm font-medium">Categories</label>
							<div className="flex gap-2 mt-1">
								{Array.isArray(fields.collectionCategories?.value) &&
									fields.collectionCategories.value.map((category) => (
										<Badge key={category} variant="secondary">
											{category}
										</Badge>
									))}
							</div>
						</div>
					</div>
				</Card>
			)}

			{/* Photos Review */}
			<div className="space-y-6">
				<h3 className="text-lg font-semibold">Photos</h3>
				{photoList.map((photo, index) => {
					const photoData = photo.getFieldset();
					const cameraData = photoData.cameraData.getFieldset();
					const tags = getTags(photoData.tags.value);

					return (
						<Card key={photo.id} className="p-6">
							<div className="grid md:grid-cols-2 gap-6">
								{/* Photo Preview */}
								<div className="aspect-square bg-muted rounded-lg flex items-center justify-center">
									{photoData.photo.value instanceof File ? (
										<img
											src={URL.createObjectURL(photoData.photo.value)}
											alt={photoData.name.value}
											className="object-cover w-full h-full rounded-lg"
										/>
									) : (
										<span className="text-muted-foreground">No photo selected</span>
									)}
								</div>

								{/* Photo Details */}
								<div className="space-y-4">
									<div>
										<Label className="text-sm font-medium">Name</Label>
										<p>{photoData.name.value}</p>
									</div>

									<div>
										<Label className="text-sm font-medium">Description</Label>
										<p className="text-sm text-muted-foreground">{photoData.description.value}</p>
									</div>

									<div className="grid grid-cols-2 gap-4">
										<div>
											<Label className="text-sm font-medium">Edition Type</Label>
											<p>{photoData.editionType.value}</p>
										</div>
										<div>
											<Label className="text-sm font-medium">Edition Size</Label>
											<p>{photoData.editionSize.value}</p>
										</div>
										<div>
											<Label className="text-sm font-medium">Price</Label>
											<p>${photoData.price.value}</p>
										</div>
									</div>

									<div>
										<Label className="text-sm font-medium">Tags</Label>
										<div className="flex flex-wrap gap-2 mt-1">
											{tags.map((tag) => (
												<Badge key={tag} variant="outline">
													{tag}
												</Badge>
											))}
										</div>
									</div>

									{/* Camera Information */}
									<div>
										<Label className="text-sm font-medium">Camera Information</Label>
										<div className="grid grid-cols-2 gap-2 mt-2 text-sm">
											<div>
												<span className="font-medium">Make:</span> {cameraData.cameraMake.value}
											</div>
											<div>
												<span className="font-medium">Model:</span> {cameraData.cameraModel.value}
											</div>
											<div>
												<span className="font-medium">Lens:</span> {cameraData.lens.value}
											</div>
											<div>
												<span className="font-medium">Shutter Speed:</span>{" "}
												{cameraData.shutterSpeed.value}
											</div>
											<div>
												<span className="font-medium">Aperture:</span> {cameraData.aperture.value}
											</div>
										</div>
									</div>
								</div>
							</div>
						</Card>
					);
				})}
			</div>
		</div>
	);
};
