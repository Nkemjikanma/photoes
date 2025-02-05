"use client";

import { useEffect, useState } from "react";

import Image from "next/image";
import Link from "next/link";
import { AddButton } from "./assets/AddButton";
import { Button } from "./ui/button";
import { Card, CardContent } from "./ui/card";
import { Skeleton } from "./ui/skeleton";

type CollectionType = {
	id: string;
	name: string;
	imageUrl: string;
	photoCount: number;
};
export const CollectionsGrid = () => {
	const [collections, setCollections] = useState<CollectionType[]>([]);
	const [isLoading, setIsLoading] = useState(true);

	useEffect(() => {
		// Simulating an API call
		setTimeout(() => {
			setCollections([
				{ id: "1", name: "Urban Landscapes", imageUrl: "/2.jpg", photoCount: 12 },
				{ id: "2", name: "Nature's Wonders", imageUrl: "/3.jpg", photoCount: 15 },
				{ id: "3", name: "Abstract Realities", imageUrl: "/4.jpg", photoCount: 8 },
				{ id: "4", name: "Serene Waters", imageUrl: "/5.jpg", photoCount: 10 },
			]);
			setIsLoading(false);
		}, 1000);
	}, []);

	if (isLoading) {
		return (
			<section className="relative w-full flex py-6">
				<div className="relative mx-auto w-5/6">
					<h4 className="font-normal">Collections</h4>
					<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mt-5">
						{Array.from({ length: 4 }).map((_, index) => (
							<Card key={index} className="overflow-hidden rounded-none">
								<CardContent className="p-0">
									<div className="w-full h-48 bg-gray-200 dark:bg-gray-700 animate-pulse" />
									<div className="p-4">
										<div className="h-6 w-3/4 bg-gray-200 dark:bg-gray-700 animate-pulse mb-2" />
										<div className="h-4 w-1/2 bg-gray-200 dark:bg-gray-700 animate-pulse" />
									</div>
								</CardContent>
							</Card>
						))}
					</div>
				</div>
			</section>
		);
	}

	if (collections.length === 0) {
		return (
			<section className="py-12 px-4 md:px-6">
				<div className="max-w-6xl mx-auto text-center">
					<h3 className="text-3xl font-bold mb-4">No Collections Yet</h3>
					<p className="text-xl mb-8">No collections have been created just yet.</p>
					<Button
						title="Add New"
						className="group cursor-pointer outline-hidden hover:rotate-90 duration-300"
					>
						<AddButton />
					</Button>
				</div>
			</section>
		);
	}

	return (
		<section className="relative flex py-6 w-full">
			<div className="mx-auto w-5/6">
				<h4 className="font-normal">Collections</h4>
				<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-2 mt-5">
					{collections.map((collection) => (
						<Card key={collection.id} className="overflow-hidden rounded-none border-zinc-600">
							<CardContent className="p-0">
								<div className="relative w-full h-48">
									<Image
										src={collection.imageUrl || "/placeholder.svg"}
										alt={collection.name}
										fill
										loading="lazy"
										className="relative object-cover object-center"
										sizes="(max-width: 768px) 83.333vw, (max-width: 1024px) 41.666vw, 20.833vw"
									/>
								</div>
								<div className="p-4">
									<h3 className="text-xl font-semibold mb-2">{collection.name}</h3>
									<p className="text-sm text-gray-500 dark:text-gray-400 mb-4">
										{collection.photoCount} photos
									</p>
									<Button asChild className="rounded-none">
										<Link href={`/collections/${collection.id}`}>View Collection</Link>
									</Button>
								</div>
							</CardContent>
						</Card>
					))}
				</div>
			</div>
		</section>
	);
};
