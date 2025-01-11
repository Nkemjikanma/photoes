import { Separator } from "@/components/ui/separator";
import { PhotoFrame } from "./assets/PhotoFrame";

export const Main = () => {
	return (
		<div className="flex flex-col gap-1">
			<PhotoFrame size="100px" />
			<Separator />
		</div>
	);
};
