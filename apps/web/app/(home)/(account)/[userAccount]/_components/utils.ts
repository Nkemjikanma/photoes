import { EditionType, UploadType } from "@/lib/types";

export const uploadType = `${UploadType}`;

export const EmptyFormState = {
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

export const EmptyPhotoItemState = {
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
		orientation: "Landscape" as const,
	},
};

export const EmptyPhotoFormState = {
	type: UploadType.Single,
	photos: [EmptyPhotoItemState],
};

export type FormPhotoInput = {
	name?: string | undefined;
	description?: string | undefined;
	editionType?: string | undefined;
	editionSize?: string | number | undefined;
	price?: string | undefined;
	category?: (string | undefined)[] | string | undefined;
	tags?: (string | undefined)[] | string | undefined;
	photo?: unknown;
	groupId?: string | undefined;
	cameraData?: {
		cameraMake?: string | undefined;
		cameraModel?: string | undefined;
		lens?: string | undefined;
		focalLength?: string | undefined;
		shutterSpeed?: string | undefined;
		aperture?: string | undefined;
		iso?: string | undefined;
		orientation?: string | undefined;
	};
};
