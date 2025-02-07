import type { ReactNode } from "react";

export default function GalleryLayout({ children }: { children: ReactNode }) {
	return <div className="full">{children}</div>;
}
