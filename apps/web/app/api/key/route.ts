import { pinata } from "@/lib/uploads";
import { type NextRequest, NextResponse } from "next/server";
import { v4 as uuidv4 } from "uuid";
const pinataJWT = process.env.PINATA_JWT;

type keyResponseType = {
	pinata_api_key: string;
	JWT: string;
};
/**
 * @notice create api key for our client side upload
 * @param req
 * @param res
 * @returns returns api key for
 */
export async function GET(req: NextRequest, res: NextResponse) {
	try {
		const uuid = uuidv4();
		const key = await pinata.keys.create({
			keyName: uuid.toString(),
			permissions: {
				// admin: true,
				endpoints: {
					data: {
						pinList: true,
						userPinnedDataTotal: false,
					},
					pinning: {
						hashMetadata: true,
						pinByHash: true,
						pinFileToIPFS: true,
						pinJSONToIPFS: true,
						pinJobs: false,
						unpin: false,
						userPinPolicy: false,
					},
				},
			},
			maxUses: 2,
		});

		const keyData = {
			pinata_api_key: key.pinata_api_key,
			JWT: key.JWT,
		};

		return NextResponse.json(keyData, { status: 200 });
	} catch (e) {
		return NextResponse.json(
			{ error: "Failed to generate API key" },
			{
				status: 500,
			},
		);
	}
}
