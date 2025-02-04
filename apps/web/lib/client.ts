import env from "@/env";
import { createThirdwebClient } from "thirdweb";

const clientId = process.env.NEXT_PUBLIC_THIRDWEB_CLIENT_ID as string;
const secretKey = process.env.THIRDWEB_SECRET_KEY;

if (!clientId) {
	throw new Error("No client ID provided");
}

export const client = createThirdwebClient({
	clientId: clientId,
	secretKey: secretKey,
});
