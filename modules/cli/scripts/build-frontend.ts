import fs from "fs/promises";
import type { BuildConfig } from "bun";
import type { BundlerConfig } from ".";

build();

async function build() {
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
}

async function getConfig(): Promise<BundlerConfig> {
  const configBytes = process.argv[3];
  return (await exec(configBytes)) as BundlerConfig;
}

async function exec(js: string) {
  const blob = new Blob([js], { type: "text/javascript" });
  const url = URL.createObjectURL(blob);

  try {
    const module = await import(url);
    return module;
  } finally {
    URL.revokeObjectURL(url);
  }
}

function extend<T extends object, U extends object, V = T & U>(
  obj: T,
  ext: U,
): V {
  return {
    ...ext,
    ...obj,
  } as V;
}
