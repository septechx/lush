import fs from "fs/promises";
import type { BuildConfig } from "bun";
import type { BundlerConfig } from ".";

const startTime = performance.now();
process.stdout.write("Building client\n");

const config = await getConfig();

await Bun.build(
  extend<BundlerConfig, BuildConfig, BuildConfig>(config, {
    entrypoints: ["./src/index.html"],
    outdir: "./dist/client",
    splitting: true,
    env: "PUBLIC_*",
    sourcemap: "linked",
  }),
).catch((e) => {
  process.stderr.write("Build failed\n");
  throw e;
});

const endTime = performance.now();
process.stdout.write(
  `Client built, took ${Math.round(endTime - startTime)}ms\n`,
);

async function getConfig(): Promise<BundlerConfig> {
  if (!(await fs.exists("bundler.config.ts"))) return {};

  const path = await fs.realpath("bundler.config.ts");
  return import(path).then((d: { default: BundlerConfig }) => d.default);
}

function extend<T extends object, U extends object, V = T & U>(
  obj: T,
  extend: U,
): V {
  return {
    ...extend,
    ...obj,
  } as V;
}
