"use client";

import { Check } from "lucide-react";
import { AnimatePresence, motion } from "motion/react";
import Image from "next/image";

import { useState } from "react";

type Category =
	| "Black and White"
	| "Travel"
	| "Nature"
	| "Portrait"
	| "Landscape"
	| "Street"
	| "Urban"
	| "Urban Landscape"
	| "Grayscale"
	| "Heavy filters"
	| "AI Variant"
	| "wildlife"
	| "nature";

type PhotoType = {
	id: number;
	title: string;
	description: string;
	image: string;
	position: "center" | "top" | "bottom" | "left" | "right"; // assuming these are the possible positions
	category: Category[];
};

const categories = [
	"Black and White",
	"Travel",
	"Nature",
	"Portrait",
	"Landscape",
	"Street",
	"Urban",
	"Urban Landscape",
	"Grayscale",
	"Heavy filters",
	"AI Variant",
];

const photos: PhotoType[] = [
	{
		id: 1,
		title: "Urban Landscape",
		description: "A stunning cityscape at twilight",
		image: "/2.jpg",
		position: "center",
		category: ["Black and White", "Travel", "Nature"],
	},
	{
		id: 2,
		title: "Natural Wonder",
		description: "Breathtaking view of a mountain range",
		image: "/3.jpg",
		position: "center",
		category: ["Landscape", "Street", "Urban"],
	},
	{
		id: 3,
		title: "Abstract Reality",
		description: "A mesmerizing play of light and shadow-sm",
		image: "/4.jpg",
		position: "center",
		category: ["Urban Landscape", "Grayscale", "Heavy filters"],
	},
	{
		id: 4,
		title: "Serene Waters",
		description: "Tranquil lake reflecting the sky",
		image: "/5.jpg",
		position: "center",
		category: ["Heavy filters", "AI Variant"],
	},
	{
		id: 5,
		title: "Wildlife Moment",
		description: "Rare capture of nature in action",
		image: "/6.jpg",
		position: "center",
		category: ["wildlife", "nature"],
	},
];

export const CategoriesDisplay = () => {
	const [selected, setSelected] = useState<string[]>([]);
	const [currentImageIndex, setCurrentImageIndex] = useState(0);

	const toggleCategory = (category: string) => {
		setSelected((prev) =>
			prev.includes(category) ? prev.filter((c) => c !== category) : [...prev, category],
		);
	};

	// Get all unique categories
	const uniqueCategories = Array.from(new Set(photos.flatMap((photo) => photo.category)));

	// Filter photos based on selected categories
	const filteredPhotos = photos.filter((photo) =>
		selected.length === 0
			? true // Show all photos if no category is selected
			: photo.category.some((cat) => selected.includes(cat)),
	);

	return (
		<section className="relative flex py-6 w-full">
			<div className="mx-auto w-5/6">
				<h4 className="font-normal mb-4">Find your categories</h4>

				<div className="relative grid grid-cols-1 md:grid-cols-4 gap-4 w-full">
					<div className="relative w-full order-2 md:order-1 md:col-span-2 lg:col-span-1">
						<motion.div
							className="flex flex-wrap gap-3"
							layout
							transition={{
								type: "spring",
								stiffness: 500,
								damping: 30,
								mass: 0.5,
							}}
						>
							{categories.map((category) => {
								const isSelected = selected.includes(category);
								return (
									<motion.button
										key={category}
										onClick={() => {
											toggleCategory(category);
										}}
										layout
										initial={false}
										animate={{
											backgroundColor: isSelected ? "oklch(0.666 0.179 58.318)" : "#f5f5f5",
										}}
										whileHover={{
											backgroundColor: isSelected ? "oklch(0.666 0.179 58.318)" : "#f5f5f5",
											scale: isSelected ? 1.2 : 0.9,
											transition: { duration: 0.1 },
										}}
										whileTap={{
											backgroundColor: isSelected ? "oklch(0.666 0.179 58.318)" : "#f5f5f5",
										}}
										transition={{
											type: "spring",
											stiffness: 500,
											damping: 30,
											mass: 0.5,
											backgroundColor: { duration: 0.1 },
										}}
										className={`
                                            inline-flex items-center py-2 px-4 rounded-none text-base font-medium
                                            whitespace-nowrap overflow-hidden ring-1 ring-inset
                                            ${
																							isSelected
																								? "text-black ring-[hsla(0,0%,100%,0.12)]"
																								: "text-zinc-500 ring-[hsla(0,0%,100%,0.06)]"
																						}
                                        `}
									>
										<motion.div
											className="relative flex items-center"
											animate={{
												width: isSelected ? "auto" : "100%",
												paddingRight: isSelected ? "1.5rem" : "0",
											}}
											transition={{
												ease: [0.175, 0.885, 0.32, 1.275],
												duration: 0.3,
											}}
										>
											<h4>{category}</h4>
											<AnimatePresence>
												{isSelected && (
													<motion.span
														initial={{ scale: 0, opacity: 0 }}
														animate={{ scale: 1, opacity: 1 }}
														exit={{ scale: 0, opacity: 0 }}
														transition={{
															type: "spring",
															stiffness: 500,
															damping: 30,
															mass: 0.5,
														}}
														className="absolute right-0"
													>
														<div className="w-4 h-4 rounded-full bg-white flex items-center justify-center">
															<Check className="w-3 h-3 text-[#2a1711]" strokeWidth={1.5} />
														</div>
													</motion.span>
												)}
											</AnimatePresence>
										</motion.div>
									</motion.button>
								);
							})}
						</motion.div>
					</div>
					{/* Image Display Section */}
					<div className="relative w-full order-1 md:order-2 md:col-span-2 lg:col-span-3 h-[500px]">
						<AnimatePresence mode="wait">
							{filteredPhotos.length > 0 ? (
								<motion.div
									key={filteredPhotos[currentImageIndex].id}
									initial={{ opacity: 0 }}
									animate={{ opacity: 1 }}
									exit={{ opacity: 0 }}
									transition={{ duration: 0.5 }}
									className="relative w-full h-full"
								>
									<Image
										src={filteredPhotos[currentImageIndex].image}
										alt={filteredPhotos[currentImageIndex].title}
										fill
										className="object-cover rounded-none"
									/>
									<div className="absolute bottom-0 left-0 right-0 p-4 bg-gradient-to-t from-black/60 to-transparent text-white rounded-b-lg">
										<h3 className="text-xl font-semibold">
											{filteredPhotos[currentImageIndex].title}
										</h3>
										<p className="text-sm">{filteredPhotos[currentImageIndex].description}</p>
									</div>
								</motion.div>
							) : (
								<motion.div
									initial={{ opacity: 0 }}
									animate={{ opacity: 1 }}
									className="w-full h-full flex items-center justify-center bg-gray-100 rounded-lg"
								>
									<p className="text-gray-500">No images found</p>
								</motion.div>
							)}
						</AnimatePresence>
					</div>
				</div>
			</div>
		</section>
	);
};
