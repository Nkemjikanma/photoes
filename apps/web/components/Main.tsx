import { CategoriesDisplay } from "@/components/CategoriesDisplay";
import { Separator } from "@/components/ui/separator";
import { CollectionsGrid } from "./CollectionsGrid";
import { LatestPhotoCarousel } from "./LatestPhotoCarousel";
import { RecentActivities } from "./RecentActivities";

import { PhotoFrame } from "./assets/PhotoFrame";

export const Main = () => {
	return (
		<div className="relative flex flex-col justify-center items-center gap-2 h-5/6 w-screen mx-auto min-w-96">
			<LatestPhotoCarousel />
			<RecentActivities />
			<CollectionsGrid />
			<CategoriesDisplay />
		</div>
	);
};
