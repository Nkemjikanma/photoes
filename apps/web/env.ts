import { type ZodError, z } from "zod";

const EnvSchema = z.object({
	NODE_ENV: z.string().default("development"),
	NEXT_PUBLIC_THIRDWEB_CLIENT_ID: z.string(),
});

export type EnvType = z.infer<typeof EnvSchema>;

const env: EnvType = (() => {
	try {
		const parsed = EnvSchema.parse(process.env);
		return parsed;
	} catch (err) {
		const error = err as ZodError;
		console.error("❌ Invalid environment variables:");
		console.log(error.flatten().fieldErrors);

		// Return default values instead of exiting
		return {
			NODE_ENV: "development",
			NEXT_PUBLIC_THIRDWEB_CLIENT_ID: "", // or throw an error if this is required
		};
	}
})();

export default env;
