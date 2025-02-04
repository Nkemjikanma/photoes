"use server";
import { client } from "@/lib/client";
import { cookies } from "next/headers";
import { type VerifyLoginPayloadParams, createAuth } from "thirdweb/auth";
import { privateKeyToAccount } from "thirdweb/wallets";
import { stringToHex } from "viem";

type PayloadParams = {
	address: string;
	chainId: number;
};

// const data = stringToHex("Hello World!", { size: 32 });

const COOKIES_CONFIG = {
	maxAge: 60 * 60 * 24 * 7, // 1 week
	path: "/",
	domain: process.env.HOST ?? "localhost",
	httpOnly: true,
	secure: process.env.NODE_ENV === "production",
};

// const privateKey = stringToHex(process.env.THIRDWEB_ADMIN_PRIVATE_KEY as string);
const privateKey = process.env.THIRDWEB_ADMIN_PRIVATE_KEY;

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
		const cookieStore = await cookies();
		cookieStore.set("jwt", jwt);
	}
}

export async function isLoggedIn() {
	const cookieStore = await cookies();
	const jwt = cookieStore.get("jwt");
	console.log("jwt", jwt);
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
