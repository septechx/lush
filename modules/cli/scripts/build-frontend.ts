import { Chalk } from "chalk";
import type { ChalkInstance } from "chalk";
import type { BuildConfig } from "bun";
import type { BundlerConfig } from ".";

build();

const chalk = new Chalk({ level: 3 });

const colors: Record<string, ChalkInstance> = {
  css: chalk.magenta,
  js: chalk.cyan,
  html: chalk.blue,
  ico: chalk.green,
  map: chalk.red,
};

async function build() {
  const realStartTime = performance.now();

  const config = await getConfig();

  const startTime = performance.now();

  const output = await Bun.build(
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

  for (const out of output.outputs) {
    process.stdout.write(`${chalk.gray("[built]")} ${genFileOut(out.path)}\n`);
  }

  const realEndTime = performance.now();

  process.stdout.write(
    `Built in ${Math.round(endTime - startTime)}ms (${Math.round(realEndTime - realStartTime)}ms). \n`,
  );
}

function genFileOut(path: string): string {
  const splitPath = path.split("/");
  const exts = splitPath[splitPath.length - 1].split(".");
  const ext = exts[exts.length - 1];

  return colors[ext](`dist/${path.split("/dist/")[1]}`);
}

async function getConfig(): Promise<BundlerConfig> {
  const configBytes = process.argv[3];
  return (await exec(configBytes)) as BundlerConfig;
}

async function exec(js: string) {
  const blob = new Blob([js], { type: "text/javascript" });
  const url = URL.createObjectURL(blob);

  try {
    return await import(url);
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
