import { PinataSDK } from "pinata-web3";

export const pinata = new PinataSDK({
	pinataJwt: process.env.PINATA_JWT,
	pinataGateway: "salmon-realistic-muskox-762.mypinata.cloud",
});

const auth = await pinata.testAuthentication()

console.log("this is auth: ", auth)

type GroupResponseItem = {
	id: string;
	user_id: string;
	name: string;
	updatedAt: string;
	createdAt: string;
};
const createGroup = async (groupName: string): Promise<GroupResponseItem> => {
	const group = await pinata.groups.create({
		name: groupName,
	});

	return group;
};

const addCIDSToGroup = async(groupId: string, cids: string[]) {
  const group = await pinata.groups.addCids({
    groupId,
    cids: [...cids]
  })

  if(group !== 'OK') {
    console.log("Error")
  }
}

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

// upload file along with the temp key
export async function uploadFile(selectedFile: File | undefined, key: string) {
	if (!selectedFile) {
		console.log("No file provided");

		return;
	}

	try {
		const formData = new FormData();
		formData.append("file", selectedFile);

		// TODO: improve metat data and pass argument with metadata
		const metadata = JSON.stringify({
			name: `${selectedFile.name}`,
		});
		formData.append("metadata", metadata);

		const options = JSON.stringify({
			cidVersion: 1,
		});
		formData.append("pinataOptions", options);

		const uploadRes = await fetch("https://api.pinata.cloud/pinning/pinFileToIPFS", {
			method: "POST",
			headers: {
				Authorization: `Bearer ${key}`,
			},
			body: formData,
		});

		console.log({ uploadStatus: uploadRes.status });

		if (uploadRes.status !== 200) {
			throw Error;
		}

		const uploadResJSON = await uploadRes.json();

		return uploadResJSON.ipfsHash;
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
