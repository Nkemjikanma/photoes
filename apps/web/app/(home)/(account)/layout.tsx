import type { ReactNode } from "react";
export default function AccountLayout({ children }: { children: ReactNode }) {
	return <div className="flex flex-col items-center min-h-screen">{children}</div>;
}
