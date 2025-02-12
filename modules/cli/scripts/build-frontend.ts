import type { BuildConfig } from "bun";
import fs from "fs/promises";

const startTime = performance.now();
process.stdout.write("Building client");

const config = await getConfig();

await Bun.build(config).catch((e) => {
  process.stderr.write("Build failed");
  throw e;
});

const endTime = performance.now();
process.stdout.write(`Client built, took ${Math.round(endTime - startTime)}ms`);

async function getConfig(): Promise<BuildConfig> {
  const configRegex = /^bundler\.config\.(js|ts)$/;

  await fs.readdir("./").then((files) =>
    files.forEach((file) => {
      if (configRegex.test(file)) {
        return import(file).then((d) => d.default) as Promise<BuildConfig>;
      }
    }),
  );

  throw new Error(
    "Build config not found, create a bundler.config.{ts,js} file",
  );
}
