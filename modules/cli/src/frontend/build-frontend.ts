import type { BuildConfig } from "bun";

const startTime = performance.now();
console.log("Building client");

// @ts-ignore
const config: BuildConfig = await import("bundler.config.ts");

await Bun.build(config).catch((e) => {
  console.error("Build failed");
  throw e;
});

const endTime = performance.now();
console.log(`Client built, took ${Math.round(endTime - startTime)}ms`);
