import { z } from "zod";

const schema = z.object({
  NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
  PORT: z.coerce.number().int().positive().default(3000),
  DATABASE_URL: z.string().min(1), REDIS_URL: z.string().url(),
  ACCESS_TOKEN_SECRET: z.string().min(32), ADMIN_ACCESS_TOKEN_SECRET: z.string().min(32),
  TOKEN_HASH_SECRET: z.string().min(32), TOTP_ENCRYPTION_KEY: z.string().min(40),
  OTP_PROVIDER: z.enum(["console", "termii"]).default("console"),
  TERMII_API_KEY: z.string().optional(), TERMII_SENDER_ID: z.string().default("Leetlogic"),
  AFRICAS_TALKING_API_KEY: z.string().optional(), AFRICAS_TALKING_USERNAME: z.string().optional(),
  AFRICAS_TALKING_SENDER_ID: z.string().default("Leetlogic"),
});
export type Config = z.infer<typeof schema>;
let cached: Config | undefined;
export function getConfig(): Config { return (cached ??= schema.parse(process.env)); }

