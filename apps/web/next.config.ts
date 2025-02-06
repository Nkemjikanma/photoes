import type { NextConfig } from "next";

const nextConfig: NextConfig = {
	/* config options here */
	eslint: {
		ignoreDuringBuilds: true,
	},
	images: {
		domains: ["http://localhost:3000"],
		formats: ["image/avif", "image/webp"],
		remotePatterns: [
			{
				protocol: "http",
				hostname: "localhost",
				port: "3000",
				pathname: "",
			},
		],
	},
};

export default nextConfig;
