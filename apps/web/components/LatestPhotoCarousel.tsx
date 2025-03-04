"use client";

import { Button } from "@/components/ui/button";
import {
	Carousel,
	type CarouselApi,
	CarouselContent,
	CarouselItem,
} from "@/components/ui/carousel";
import { Loader2, MoveRight } from "lucide-react";
import Image from "next/image";
import { useRouter } from "next/navigation";
import { useCallback, useEffect, useRef, useState } from "react";

interface LatestPhotoCarouselProps {
	intervalTime?: number; // Time in milliseconds
	autoplayEnabled?: boolean;
}

const featuredPhotos = [
	{
		id: 1,
		title: "Urban Landscape",
		description: "A stunning cityscape at twilight",
		image: "/2.jpg",
		position: "center",
		collectionId: 1,
	},
	{
		id: 2,
		title: "Natural Wonder",
		description: "Breathtaking view of a mountain range",
		image: "/3.jpg",
		position: "center",
		collectionId: 2,
	},
	{
		id: 3,
		title: "Abstract Reality",
		description: "A mesmerizing play of light and shadow-sm",
		image: "/4.jpg",
		position: "center",
		collectionId: 3,
	},
	{
		id: 4,
		title: "Serene Waters",
		description: "Tranquil lake reflecting the sky",
		image: "/5.jpg",
		position: "center",
		collectionId: 4,
	},
	{
		id: 5,
		title: "Wildlife Moment",
		description: "Rare capture of nature in action",
		image: "/6.jpg",
		position: "center",
		collectionId: 5,
	},
];

export const LatestPhotoCarousel = ({
	intervalTime = 5000, // 5 secs
	autoplayEnabled = true,
}: LatestPhotoCarouselProps) => {
	const timerRef = useRef<NodeJS.Timeout | null>(null);
	const [carouselApi, setCarouselApi] = useState<CarouselApi>();
	const [currentIndex, setCurrentIndex] = useState(0);
	const [isLoading, setIsLoading] = useState(true);
	const router = useRouter();

	useEffect(() => {
		setIsLoading(false);
	}, []);

	const startAutoPlay = useCallback(() => {
		if (timerRef.current) clearInterval(timerRef.current);

		const newTimer = setInterval(() => {
			if (carouselApi?.canScrollNext()) {
				carouselApi.scrollNext();
			} else {
				carouselApi?.scrollTo(0);
			}
		}, intervalTime);
		timerRef.current = newTimer;
	}, [carouselApi, intervalTime]);

	useEffect(() => {
		if (!carouselApi) return;

		const onSelect = () => {
			setCurrentIndex(carouselApi.selectedScrollSnap());
		};

		carouselApi.on("select", onSelect);
		return () => {
			carouselApi.off("select", onSelect);
		};
	}, [carouselApi]);

	useEffect(() => {
		if (!carouselApi || !autoplayEnabled) return;

		startAutoPlay();

		return () => {
			if (timerRef.current) clearInterval(timerRef.current);
		};
	}, [carouselApi, startAutoPlay, autoplayEnabled]);

	return (
		<div className="relative flex flex-col items-center dark:bg-black min-w-screen w-full">
			<div className="relative w-full flex flex-col justify-center items-center">
				<div className="flex justify-between py-4 w-10/12">
					<h4 className="font-normal">FEATURED PHOTOS</h4>
					<a
						href="/gallery"
						className="text-sm text-zinc-500 hover:text-zinc-800 flex items-center"
					>
						VIEW ALL
						<MoveRight className="h-4 w-4 ml-1" />
					</a>
				</div>

				<div className="relative flex flex-col items-center w-10/12 h-[62vh]">
					{isLoading ? (
						<div className="flex justify-center items-center h-64">
							<Loader2 className="h-8 w-8 animate-spin" />
						</div>
					) : (
						<Carousel
							setApi={setCarouselApi}
							onMouseEnter={() => {
								if (timerRef.current) {
									clearInterval(timerRef.current);
								}
							}}
							onMouseLeave={startAutoPlay}
							className="absolute flex flex-col w-full h-full"
							opts={{
								align: "start",
								// loop: true,
								slidesToScroll: 1,
							}}
						>
							<CarouselContent className="relative h-full w-full mx-auto">
								{featuredPhotos.map((photo, index) => (
									<CarouselItem key={photo.id} className="relative h-[60vh] px-1">
										<div className="relative h-full w-full overflow-hidden group">
											{/* <div className="absolute inset-0 bg-black bg-opacity-30" />{" "} */}
											{/* Reduced opacity */}
											<Image
												src={photo.image}
												alt={photo.title}
												fill
												quality={100}
												className="relative object-cover object-center h-auto scale-105 group-hover:scale-100 transition-transform duration-300 aspect-3/2 inline max-w-none"
												priority={true}
												sizes="(max-width: 768px) 100vw, (max-width: 1200px) 80vw, 70vw"
												onError={(e) => {
													console.error(`Failed to load image: ${photo.image}`);
													e.currentTarget.src = "/placeholder.svg";
												}}
												onLoad={() => {
													console.log(`Successfully loaded image: ${photo.image}`);
												}}
											/>
											<img
												src={photo.image}
												alt={photo.title}
												width="400px"
												className="aspect-3/2 inline max-w-none"
											/>
											<div className="absolute inset-0 bg-black bg-opacity-50" />
											<div className="absolute inset-0 flex flex-col justify-center items-center text-white text-center p-4">
												<h1
													className={`text-3xl md:text-4xl lg:text-5xl font-bold mb-2 md:mb-4 transition-all duration-500 ${
														currentIndex === index
															? "opacity-100 translate-y-0"
															: "opacity-0 translate-y-4"
													}`}
												>
													{photo.title}
												</h1>
												<p
													className={`text-lg md:text-xl mb-4 md:mb-8 max-w-md transition-all duration-500 delay-100 ${
														currentIndex === index
															? "opacity-100 translate-y-0"
															: "opacity-0 translate-y-4"
													}`}
												>
													{photo.description}
												</p>
												<div
													className={`flex flex-col sm:flex-row gap-4 transition-all duration-500 delay-200 ${
														currentIndex === index
															? "opacity-100 translate-y-0"
															: "opacity-0 translate-y-4"
													}`}
												>
													<Button
														size="lg"
														className="rounded-none bg-black backdrop-blur-md isolation-auto border-gray-50 before:absolute before:w-full before:transition-all before:duration-700 hover:before:w-full before:-left-full hover:before:left-0 before:rounded-full before:bg-amber-600 hover:text-gray-50 dark:text-gray-50 before:-z-10 before:aspect-square hover:before:scale-150 hover:before:duration-700 relative z-10 px-4 py-2 overflow-hidden group"
														onClick={() => {
															router.push(`/gallery/${photo.collectionId}`);
														}}
													>
														Explore Collection
													</Button>
													<Button
														size="lg"
														variant="outline"
														className="bg-amber-600 rounded-none text-black dark:text-white dark:hover:bg-zinc-900"
													>
														Learn More
													</Button>
												</div>
											</div>
										</div>
									</CarouselItem>
								))}
							</CarouselContent>
						</Carousel>
					)}
				</div>

				<div className="absolute bottom-12 left-0 right-0 flex justify-center gap-2 z-10">
					{featuredPhotos.map((photo, index) => (
						<button
							key={photo.id}
							type="button"
							onClick={() => carouselApi?.scrollTo(index)}
							className={`w-2 h-2 rounded-full transition-all ${
								currentIndex === index
									? "bg-amber-600 dark:bg-amber-600 w-4"
									: "bg-gray-300 hover:bg-gray-400"
							}`}
						/>
					))}
				</div>
			</div>
		</div>
	);
};
