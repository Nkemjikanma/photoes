"use server";
import { client } from "@/lib/client";
import { cookies } from "next/headers";
import { type VerifyLoginPayloadParams, createAuth } from "thirdweb/auth";
import type { JWTPayload } from "thirdweb/utils";
import { privateKeyToAccount } from "thirdweb/wallets";

type PayloadParams = {
	address: string;
	chainId: number;
};

// payload?: SignLoginPayloadParams;
type AdminCheckResult = {
	isAdmin: boolean;
	payload?: JWTPayload;
	error?: string;
};

const privateKey = process.env.THIRDWEB_ADMIN_PRIVATE_KEY;
const ADMIN_ADDRESS = process.env.DEV_ADDRESS;

// Validate private key
if (!privateKey || !privateKey.startsWith("0x")) {
	throw new Error(
		"Invalid or missing THIRDWEB_ADMIN_PRIVATE_KEY in environment variables. Must be a hex string starting with 0x",
	);
}

const thirdwebAuth = createAuth({
	domain: process.env.NEXT_PUBLIC_THIRDWEB_AUTH_DOMAIN || "",
	adminAccount: privateKeyToAccount({ client, privateKey }),
	client,
});

export const generatePayload = async ({ address, chainId }: PayloadParams) => {
	return thirdwebAuth.generatePayload({ address, chainId });
};

export async function login(payload: VerifyLoginPayloadParams) {
	const cookieStore = await cookies();
	const verifyPayload = await thirdwebAuth.verifyPayload(payload);

	if (verifyPayload.valid) {
		const jwt = await thirdwebAuth.generateJWT({
			payload: verifyPayload.payload,
		});
		cookieStore.set("jwt", jwt);
	}
}

export async function isLoggedIn() {
	const cookieStore = await cookies();
	const jwt = cookieStore.get("jwt");
	if (!jwt?.value) {
		return false;
	}
	const authResult = await thirdwebAuth.verifyJWT({ jwt: jwt.value });
	if (!authResult.valid) {
		return false;
	}
	return true;
}

export async function logout() {
	const cookieStore = await cookies();
	cookieStore.delete("jwt");
}

export async function isAdmin(): Promise<AdminCheckResult> {
	try {
		const cookieStore = await cookies();
		const jwt = cookieStore.get("jwt");

		if (!jwt?.value) {
			return {
				isAdmin: false,
				error: "No JWT token found",
			};
		}

		const authResult = await thirdwebAuth.verifyJWT({ jwt: jwt.value });
		if (!authResult.valid) {
			return {
				isAdmin: false,
				error: authResult.error,
			};
		}

		console.log("authed", authResult.parsedJWT);

		const isAdminAddress = authResult.parsedJWT.sub.toLowerCase() === ADMIN_ADDRESS?.toLowerCase();
		// Additional security checks
		const currentTime = Math.floor(Date.now() / 1000);
		const tokenNotExpired = currentTime <= authResult.parsedJWT.exp;
		const tokenActive = currentTime >= authResult.parsedJWT.nbf;

		if (!isAdminAddress) {
			return {
				isAdmin: false,
				error: "Address is not authorized as admin",
				payload: authResult.parsedJWT,
			};
		}

		if (!tokenNotExpired) {
			return {
				isAdmin: false,
				error: "Token has expired",
				payload: authResult.parsedJWT,
			};
		}

		if (!tokenActive) {
			return {
				isAdmin: false,
				error: "Token not yet active",
				payload: authResult.parsedJWT,
			};
		}

		return {
			isAdmin: isAdminAddress,
			payload: authResult.parsedJWT,
		};
	} catch (error) {
		console.error("Admin check failed:", error);
		return {
			isAdmin: false,
			error: error instanceof Error ? error.message : "Unknown error occurred",
		};
	}
}
