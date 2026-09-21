import { Redis } from "ioredis";
import { getConfig } from "../config.js";
let client: Redis | undefined;
export function redis(): Redis { return (client ??= new Redis(getConfig().REDIS_URL, { maxRetriesPerRequest: 2 })); }
