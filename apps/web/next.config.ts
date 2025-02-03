import type { NextConfig } from "next";

const nextConfig: NextConfig = {
	/* config options here */
	eslint: {
		ignoreDuringBuilds: true,
	},

	images: {
		formats: ["image/avif", "image/webp"],
		remotePatterns: [
			{
				protocol: "https",
				hostname: "localhost",
				port: "3000",
				pathname: "",
			},
		],
	},
};

export default nextConfig;
