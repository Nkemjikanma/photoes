import { z } from "zod";

export type UploadType = "single" | "collection";

export enum EditionType {
	Single = "SINGLE", // ERC721
	Multiple = "MULTIPLE", // ERC1155
}

export const EditionTypeSchema = z.enum(["SINGLE", "MULTIPLE"]);

export enum CollectionCategory {
	Photography = "PHOTOGRAPHY",
	Art = "ART",
	Portrait = "PORTRAIT", // People, faces, personalities
	Landscape = "LANDSCAPE", // Natural scenery, outdoor views
	Wildlife = "WILDLIFE", // Animals in their natural habitat
	Street = "STREET", // Urban life, candid moments
	Architecture = "ARCHITECTURE", // Buildings, structures, designs
	Fashion = "FASHION", // Style, clothing, modeling
	Documentary = "DOCUMENTARY", // Journalistic, storytelling
	Sports = "SPORTS", // Athletic events, action shots
	Macro = "MACRO", // Close-up, detailed shots
	Abstract = "ABSTRACT", // Artistic, non-representational
	Event = "EVENT", // Weddings, celebrations, gatherings
	Travel = "TRAVEL", // Places, cultures, destinations
	Food = "FOOD", // Culinary, dishes, ingredients
	Commercial = "COMMERCIAL", // Product, advertising
	Aerial = "AERIAL", // Drone, bird's eye view
	Black_And_White = "BLACK_AND_WHITE", // Monochrome photography
	Night = "NIGHT", // Low light, astrophotography
	Nature = "NATURE", // Flora, landscapes, natural phenomena
	Still_Life = "STILL_LIFE", // Arranged objects, compositions
	Other = "OTHER", // Miscellaneous
}

export const CollectionCategorySchema = z.enum([
	"PHOTOGRAPHY",
	"ART",
	"PORTRAIT",
	"LANDSCAPE",
	"WILDLIFE",
	"STREET",
	"ARCHITECTURE",
	"FASHION",
	"DOCUMENTARY",
	"SPORTS",
	"MACRO",
	"ABSTRACT",
	"EVENT",
	"TRAVEL",
	"FOOD",
	"COMMERCIAL",
	"AERIAL",
	"BLACK_AND_WHITE",
	"NIGHT",
	"NATURE",
	"STILL_LIFE",
	"OTHER",
]);

// Interfaces/Types
export interface CollectionMetadata {
	coverImageURI: string;
	featuredPhotoURI: string;
	tags: string[];
}

export interface CollectionCreationParams {
	name: string;
	description: string;
	categories: CollectionCategory[];
	photoCreationParams: PhotoCreationParams[];
	tags: string[];
	coverImageURI: string;
	featuredPhotoURI: string;
}

export interface Collection {
	collectionId: number;
	name: string;
	description: string;
	creator: string; // address
	createdAt: number;
	category: CollectionCategory[];
	metadata: CollectionMetadata;
	photoIds: number[]; // All photoids in this collection
}

export interface PhotoCreationParams {
	name: string;
	description: string;
	tokenURI: string;
	editionSize: number;
	price: number;
}

export interface MintPhotoParams {
	name: string;
	description: string;
	tokenURI: string;
	editionType: EditionType;
	editionSize: number;
	price: number;
	collectionId: number;
}

export interface Photo {
	tokenId: number;
	name: string;
	description: string;
	tokenURI: string;
	editionType: EditionType;
	editionSize: number;
	price: number;
	isActive: boolean;
	creator: string; // address
	createdAt: number;
	collectionId: number; // 0 if not part of collection
	aiVariantIds: number[]; // AI variants generated for this photo
	editionOwners: Record<string, EditionOwnership>; // mapping address to EditionOwnership
	ownersList: string[]; // List of all owners (addresses)
	totalEditionsSold: number;
}

export interface PhotoView {
	tokenId: number;
	name: string;
	description: string;
	tokenURI: string;
	editionType: EditionType;
	editionSize: number;
	price: number;
	isActive: boolean;
	creator: string; // address
	createdAt: number;
	collectionId: number;
	aiVariantIds: number[];
	ownersList: string[]; // addresses
	totalEditionsSold: number;
}

export interface EditionOwnership {
	copiesOwned: number;
	aiVariantIds: number[];
	exists: boolean;
	purchaseDate: number;
}

export interface AiGeneratedVariant {
	originalPhotoId: number;
	aiURI: string;
	variantId: number;
	generationDate: number;
	isMinted: boolean;
	owner: string; // address
	editionNumber: number; // Which edition of the original this variant belongs to
}

export interface UserAiVariant {
	aiTokenId: number;
	owner: string; // address
	originalPhotoTokenId: number;
}

// Some notes about the conversion:
// 1. Solidity `uint256`, `uint96`, `uint32` are converted to TypeScript `number`
// 2. Solidity `address` type is represented as `string` in TypeScript
// 3. Mappings are converted to `Record<string, T>` where the key is an address

// You can also add utility types for contract interactions:

// ```typescript
// // For function parameters
// export type CreateCollectionParams = Omit<Collection, 'collectionId' | 'createdAt'>;
