"use client";

import { CommandSearch } from "@/components/CommandSearch";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { Loader2, MoveLeft } from "lucide-react";
import { AnimatePresence, motion } from "motion/react";
import Image from "next/image";
import { useRouter } from "next/navigation";

const GalleryPage = () => {
	const router = useRouter();
	const collections = [
		{
			id: "1",
			name: "Urban Landscapes",
			imageUrl: "/2.jpg",
			photoCount: 12,
			description: "A stunning cityscape at twilight",
		},
		{
			id: "2",
			name: "Nature's Wonders",
			imageUrl: "/3.jpg",
			photoCount: 15,
			description: "A stunning cityscape at twilight",
		},
		{
			id: "3",
			name: "Abstract Realities",
			imageUrl: "/4.jpg",
			photoCount: 8,
			description: "A stunning cityscape at twilight",
		},
		{
			id: "4",
			name: "Serene Waters",
			imageUrl: "/5.jpg",
			photoCount: 10,
			description: "A stunning cityscape at twilight",
		},
		{
			id: "5",
			name: "Oguta Waters",
			imageUrl: "/5.jpg",
			photoCount: 20,
			description: "The lake view waters",
		},
	];
	return (
		<div className="relative w-screen min-w-96 flex flex-col justify-center items-center gap-2 h-full mx-auto">
			<div className="flex justify-between py-4 w-10/12">
				<a href="/" className="text-sm text-zinc-500 hover:text-zinc-800 flex items-center">
					<MoveLeft className="h-4 w-4 mr-1" />
					BACK
				</a>
				<CommandSearch />
			</div>
			<div className="relative flex flex-col items-center w-10/12 min-h-[85vh] overflow-hidden mx-auto gap-3">
				<AnimatePresence>
					{collections.map((collection, index) => {
						return (
							<motion.div
								key={collection.id}
								initial={{ opacity: 0, y: 20 }}
								animate={{ opacity: 1, y: 0 }}
								exit={{ opacity: 0, y: -20 }}
								transition={{ duration: 0.5, delay: index * 0.1 }}
								className="relative w-full"
							>
								<Card className="relative rounded-none shadow-lg border-zinc-600 dark:shadow-xs dark:shadow-gray-600">
									<CardContent className="p-0 h-full">
										<div className="relative aspect-[16/9] w-full h-60">
											{/* Image Section */}
											<Image
												src={collection.imageUrl}
												alt={collection.name}
												fill
												className="object-cover"
												sizes="(max-width: 1200px) 100vw"
											/>

											{/* Description Overlay Section */}
											<div
												className={`absolute top-0 h-full w-2/5 bg-black/70 p-4 flex flex-col justify-center
																								${index % 2 === 0 ? "right-0" : "left-0"}`}
											>
												<h2 className="text-2xl font-bold text-white hover:text-blue-400 transition-colors duration-300">
													{collection.name}
												</h2>
												<p className="text-gray-200 leading-relaxed my-4">
													{collection.description}
												</p>

												<Button
													type="button"
													variant="outline"
													className="w-fit rounded-none text-white hover:text-amber-600 transition-colors duration-300"
													onClick={() => router.push(`/collections/${collection.id}`)}
												>
													Open collection
												</Button>
											</div>
										</div>
									</CardContent>
								</Card>
							</motion.div>
						);
					})}

					{collections.length > 0 && (
						<div className="flex items-center justify-center w-full h-full">
							<Button
								type="button"
								variant="outline"
								className="w-fit mt-2 rounded-none text-black dark:text-white hover:text-amber-600 transition-colors duration-300"
							>
								Load more
							</Button>
						</div>
					)}
				</AnimatePresence>
			</div>
		</div>
	);
};

export default GalleryPage;
