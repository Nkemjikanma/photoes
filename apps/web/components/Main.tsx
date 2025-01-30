import { Separator } from "@/components/ui/separator";
import { LatestPhotoCarousel } from "./LatestPhotoCarousel";
import { PhotoFrame } from "./assets/PhotoFrame";

export const Main = () => {
	return (
		<div className="relative flex flex-col justify-center items-center gap-2 h-5/6 w-5/6">
			{/* <PhotoFrame size="60px" /> */}
			<LatestPhotoCarousel />
			{/*category grid */}Press anytime to CMD-K search
		</div>
	);
};
