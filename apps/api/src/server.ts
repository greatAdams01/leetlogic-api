import { createApp } from "./app.js";
import { getConfig } from "./config.js";
const config = getConfig();
const server = createApp().listen(config.PORT, () => console.info(`Leetlogic API listening on :${config.PORT}`));
for (const signal of ["SIGTERM", "SIGINT"] as const) process.on(signal, () => server.close(() => process.exit(0)));

