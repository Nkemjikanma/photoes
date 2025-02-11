"use client";

import { CommandSearch } from "@/components/CommandSearch";
import { PhotoItem, type PhotoItemProp } from "@/components/PhotoItem";

import { MoveLeft } from "lucide-react";
export const CollectionId = () => {
	const photos: PhotoItemProp[] = [
		{
			id: 1,
			url: "/2.jpg",
			title: "Sunset at the Beach",
			photographer: "John Doe",
			location: "Malibu, California",
			date: "January 15, 2024",
			description: "A beautiful sunset captured at the beach during golden hour.",
		},
		{
			id: 2,
			url: "/3.jpg",
			title: "Sunset at the Beach",
			photographer: "John Doe",
			location: "Malibu, California",
			date: "January 15, 2024",
			description: "A beautiful sunset captured at the beach during golden hour.",
		},
		{
			id: 3,
			url: "/4.jpg",
			title: "Sunset at the Beach",
			photographer: "John Doe",
			location: "Malibu, California",
			date: "January 15, 2024",
			description: "A beautiful sunset captured at the beach during golden hour.",
		},
		// Add more photos here
	];
	return (
		<>
			{" "}
			<div className="flex justify-between py-4 w-10/12">
				<a href="/gallery" className="text-sm text-zinc-500 hover:text-zinc-800 flex items-center">
					<MoveLeft className="h-4 w-4 mr-1" />
					BACK
				</a>
				<CommandSearch />
			</div>
			<div className="relative w-10/12 h-screen snap-y snap-mandatory">
				{photos.map((photo, index) => (
					<PhotoItem key={photo.id} photo={photo} index={index} />
				))}
			</div>
		</>
	);
};
