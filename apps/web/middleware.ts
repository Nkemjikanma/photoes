import { type NextRequest, NextResponse } from "next/server";
import { isAdmin } from "./lib/auth";

export async function middleware(request: NextRequest) {
	if (request.nextUrl.pathname.startsWith("/admin")) {
		const adminCheck = await isAdmin();

		if (!adminCheck.isAdmin) {
			const errorMessage = adminCheck.error || "Unauthorized";

			return NextResponse.redirect(
				new URL(`/error?message=${encodeURIComponent(errorMessage)}`, request.url),
			);
		}
	}

	// Return JSON response for API routes
	if (request.nextUrl.pathname.startsWith("/admin/api")) {
		const adminCheck = await isAdmin();

		if (!adminCheck.isAdmin) {
			const errorMessage = adminCheck.error || "Unauthorized";

			return NextResponse.json({ error: errorMessage }, { status: 401 });
		}
	}

	return NextResponse.next();
}

export const config = {
	matcher: "/admin/:path*",
};
