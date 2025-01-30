"use client";

import { Card, CardContent } from "@/components/ui/card";
import {
	Carousel,
	type CarouselApi,
	CarouselContent,
	CarouselItem,
} from "@/components/ui/carousel";
import { Loader2, MoveRight } from "lucide-react";
import Image from "next/image";
import { useCallback, useEffect, useRef, useState } from "react";

interface LatestPhotoCarouselProps {
	intervalTime?: number; // Time in milliseconds
	autoplayEnabled?: boolean;
}

const cameras = [
	{
		name: "Nikon EF92",
		image:
			"https://hebbkx1anhila5yf.public.blob.vercel-storage.com/Screenshot%202025-01-30%20at%2018.51.56-JOFpNzrMHXOl6XZvrkvfIFan9gfqvp.png",
		alt: "Nikon EF92 film camera",
	},
	{
		name: "Samsung Fino",
		image:
			"https://hebbkx1anhila5yf.public.blob.vercel-storage.com/Screenshot%202025-01-30%20at%2018.51.56-JOFpNzrMHXOl6XZvrkvfIFan9gfqvp.png",
		alt: "Samsung Fino film camera",
	},
	{
		name: "Minolta F15",
		image:
			"https://hebbkx1anhila5yf.public.blob.vercel-storage.com/Screenshot%202025-01-30%20at%2018.51.56-JOFpNzrMHXOl6XZvrkvfIFan9gfqvp.png",
		alt: "Minolta F15 film camera",
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
		<div className="flex flex-col items-center relative h-full w-full dark:bg-black">
			{isLoading ? (
				<div className="flex justify-center items-center h-64">
					<Loader2 className="h-8 w-8 animate-spin" />
				</div>
			) : (
				<div className="relative flex flex-col justify-center w-full h-full">
					<div className="flex justify-between items-center py-4">
						<h4 className="font-medium">FEATURED PHOTOS</h4>
						<a
							href="#"
							className="text-sm text-muted-foreground hover:text-foreground flex items-center"
						>
							VIEW ALL
							<MoveRight className="h-4 w-4 ml-1" />
						</a>
					</div>
					<Carousel
						setApi={setCarouselApi}
						onMouseEnter={() => {
							if (timerRef.current) {
								clearInterval(timerRef.current);
							}
						}}
						onMouseLeave={startAutoPlay}
						className="flex-grow"
						opts={{
							align: "start",
							// loop: true,
							slidesToScroll: 1,
						}}
					>
						<CarouselContent className="relative -ml-1">
							{Array.from({ length: 5 }).map((_, index) => (
								<CarouselItem key={index} className="pl-1 basis-1/3">
									<Card className="h-full bg-[#f5f5f5] dark: border-0 rounded-none">
										<CardContent className="aspect-square relative">
											{/* <Image
												src={camera.image || "/placeholder.svg"}
												alt={camera.alt}
												fill
												className="object-contain p-4"
												sizes="33vw"
											/> */}
										</CardContent>
									</Card>
								</CarouselItem>
							))}
						</CarouselContent>

						<div className="flex justify-center gap-2 mt-1">
							{cameras.map((_, index) => (
								<button
									key={index}
									type="button"
									onClick={() => carouselApi?.scrollTo(index)}
									className={`w-2 h-2 rounded-full transition-all ${
										currentIndex === index
											? "bg-amber-600 dark:bg-gray-200 w-4"
											: "bg-gray-300 hover:bg-gray-400"
									}`}
								/>
							))}
						</div>
					</Carousel>
				</div>
			)}
		</div>
	);
};
