import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import {
	Carousel,
	type CarouselApi,
	CarouselContent,
	CarouselItem,
	CarouselNext,
	CarouselPrevious,
} from "@/components/ui/carousel";
// import { useCarousel } from "@/components/ui/carousel"; // You'll need to export this
import { Loader2 } from "lucide-react";
import { useCallback, useEffect, useRef, useState } from "react";

interface LatestPhotoCarouselProps {
	intervalTime?: number; // Time in milliseconds
	autoplayEnabled?: boolean;
	photos?: Array<{ id: string; url: string; title: string }>;
}

export const LatestPhotoCarousel = ({
	intervalTime = 5000, // 5 secs
	autoplayEnabled = true,
	photos = [],
}: LatestPhotoCarouselProps) => {
	const timerRef = useRef<NodeJS.Timeout | null>(null);
	const [carouselApi, setCarouselApi] = useState<CarouselApi>();
	const [currentIndex, setCurrentIndex] = useState(0);
	const [isLoading, setIsLoading] = useState(true);

	// Set loading to false when component mounts
	useEffect(() => {
		setIsLoading(false);
	}, []);

	const startAutoPlay = useCallback(() => {
		if (timerRef.current) clearInterval(timerRef.current); // check if there is an existing timer and clear it

		const newTimer = setInterval(() => {
			if (carouselApi?.canScrollNext()) {
				// check if there is a next scroll
				carouselApi.scrollNext();
			} else {
				carouselApi?.scrollTo(0);
			}
		}, intervalTime);
		timerRef.current = newTimer;
	}, [carouselApi, intervalTime]);

	// if (error) {
	// 	return <div className="flex justify-center items-center h-64 text-red-500">Error: {error}</div>;
	// }

	// carousel intiialization and cleanup
	// Effect for API initialization
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

	// Effect for autoplay
	useEffect(() => {
		if (!carouselApi) return;

		startAutoPlay();

		return () => {
			if (timerRef.current) clearInterval(timerRef.current);
		};
	}, [carouselApi, startAutoPlay]);

	console.log("isLoading -> ", isLoading);

	return (
		<div className="flex flex-col items-center relative w-fit md:px-6">
			{isLoading ? (
				<div className="flex justify-center items-center h-64">
					<Loader2 className="h-8 w-8 animate-spin" />
				</div>
			) : (
				<div className="flex flex-col justify-center w-full">
					<Carousel
						setApi={setCarouselApi}
						onMouseEnter={() => {
							if (timerRef.current) {
								clearInterval(timerRef.current);
							}
						}}
						onMouseLeave={startAutoPlay}
						className="flex items-center justify-center relative w-full"
					>
						<CarouselContent className="-ml-2 md:ml-4 w-4/5">
							{Array.from({ length: 5 }).map((_, index) => (
								<CarouselItem key={index}>
									<div className="p-1 shadow-lg border">
										<Card className="rounded-none">
											<CardContent className="flex aspect-square items-center justify-center p-12 rounded-none">
												<span className="text-4xl font-semibold">{index + 1}</span>
											</CardContent>
										</Card>
									</div>
								</CarouselItem>
							))}
						</CarouselContent>
						{/* <CarouselPrevious />
						<CarouselNext /> */}
					</Carousel>

					{/* Slide indicators */}
					<div className="flex justify-center gap-2 mt-3">
						{Array.from({ length: 5 }).map((_, index) => (
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
				</div>
			)}
		</div>
	);
};
