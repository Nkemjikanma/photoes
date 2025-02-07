import { PinataSDK } from "pinata-web3";

export const pinata = new PinataSDK({
	pinataJwt: process.env.PINATA_JWT,
	pinataGateway: process.env.PINATA_GATEWAY,
});

export interface SelectedFilesType {
	selectedFiles: FileList;
}
const auth = await pinata.testAuthentication();

console.log("this is auth: ", auth);

type GroupResponseItem = {
	id: string;
	user_id: string;
	name: string;
	updatedAt: string;
	createdAt: string;
};

// get temp api key for uploads
export const generatePinataKey = async () => {
	try {
		const temporalKey = await fetch("/api/key", {
			method: "GET",
			headers: {
				"Content-Type": "application/json",
			},
		});

		const temporalKeyData = await temporalKey.json();

		return temporalKeyData;
	} catch (e) {
		console.log("error creating api key:", e);
		throw e;
	}
};

const createGroup = async (groupName: string): Promise<GroupResponseItem> => {
	const group = await pinata.groups.create({
		name: groupName,
	});

	return group;
};

const addCIDSToGroup = async (groupId: string, cids: string[]) => {
	const group = await pinata.groups.addCids({
		groupId,
		cids: [...cids],
	});

	if (group !== "OK") {
		console.log("Error");
	}
};

// upload file along with the temp key
export async function uploadFiles(selectedFiles: File[], key: string, groupName?: string) {
	if (!selectedFiles || selectedFiles.length === 0) {
		console.log("No files provided");
		return;
	}

	try {
		// if is new upload single upload, send to base group
		if (selectedFiles.length === 1 && !groupName) {
			// TODO: Add Base group id
			const uploadData = await pinata.upload.file(selectedFiles[0]).key(key).group("Base group id");
			const url = await pinata.gateways.convert(uploadData.IpfsHash);

			return url;
		}

		// create new group
		if (selectedFiles.length > 1 && groupName) {
			const newGroup: GroupResponseItem = await createGroup(groupName);
			const uploadData = await pinata.upload
				.fileArray([...selectedFiles])
				.key(key)
				.group(newGroup.id);

			const url = await pinata.gateways.convert(uploadData.IpfsHash);

			return url;
		}
	} catch (e) {
		console.log("Error uploading file", e);
	}
}

// create and upload metadata
export async function uploadJSON(content: any, key: string) {
	try {
		const data = JSON.stringify({
			pinataContent: {
				name: content.name,
				description: content.description,
				image: `ipfs://${content.image}`,
				external_url: content.external_url,
			},
			pinataOptions: {
				cidVersion: 1,
			},
		});

		const uploadResponse = await fetch("https://api.pinata.cloud/pinning/pinJSONToIPFS", {
			method: "POST",
			headers: {
				"Content-Type": "application/json",
				Authorization: `Bearer ${key}`,
			},
			body: data,
		});

		const uploadResponseJSON = await uploadResponse.json();

		const cid = uploadResponseJSON.ipfsHash;
		console.log(cid);

		return cid;
	} catch (e) {
		console.log("Error uploading file:", e);
	}
}
