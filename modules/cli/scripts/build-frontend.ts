import type { BuildConfig } from "bun";
import fs from "fs/promises";

const startTime = performance.now();
process.stdout.write("Building client\n");

const config = await getConfig();

await Bun.build(config).catch((e) => {
  process.stderr.write("Build failed\n");
  throw e;
});

const endTime = performance.now();
process.stdout.write(`Client built, took ${Math.round(endTime - startTime)}ms\n`);

async function getConfig(): Promise<BuildConfig> {
  const configRegex = /^bundler\.config\.(js|ts)$/;
  const files = await fs.readdir("./");

  for (const file of files) {
    if (configRegex.test(file)) {
      return import(`../../../../${file}`).then((d: { default: BuildConfig }) => d.default);
    }
  }

  throw new Error("Build config not found, create a bundler.config.{ts,js} file.");
}

