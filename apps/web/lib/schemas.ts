import { z } from "zod";
import { CollectionCategoryEnum, EditionTypeEnum } from "./types";

export const singlePhotoSchema = z.object({
	name: z.string().min(1, "Name is required").max(100),
	description: z.string().max(1000),
	editionType: EditionTypeEnum,
	editionSize: z.coerce.number().min(1, "Edition size must be at least 1"),
	price: z.coerce.number().min(0, "Price must be positive"),
	photo: z.any().refine((val) => val instanceof File || !val, {
		message: "Photo must be a file",
	}),
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
	tags: z.array(CollectionCategoryEnum),
});

export const uploadFormSchema = z.discriminatedUnion("type", [
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
