import { basename } from "path";
import { Chalk } from "chalk";
import { StdOuts } from "..";
import { lush } from "./lush";
import type { ChalkInstance } from "chalk";
import type { BuildConfig } from "bun";
import type { BundlerConfig, Result } from "..";

const chalk = new Chalk({ level: 3 });

const colors: Record<string, ChalkInstance> = {
  css: chalk.magenta,
  js: chalk.cyan,
  html: chalk.blue,
  ico: chalk.yellow,
  map: chalk.red,
};

export interface BuildResult {
  stdouts: StdOuts;
  result: Result;
}

export async function build(
  dev: boolean,
  config: BundlerConfig,
): Promise<BuildResult> {
  const realStartTime = performance.now();

  const outs = new StdOuts();

  const startTime = performance.now();

  const output = await Bun.build(
    concatPlugins(
      extend<BundlerConfig, BuildConfig, BuildConfig>(config, {
        entrypoints: ["src/routes/index.html"],
        outdir: "dist/client",
        splitting: true,
        env: "PUBLIC_*",
        sourcemap: "linked",
      }),
      [lush],
    ),
  ).catch((e) => {
    outs.error("Build failed\n");
    throw e;
  });

  const endTime = performance.now();

  if (!dev) {
    for (const out of output.outputs) {
      outs.print(`${chalk.gray("[built]")} ${genFileOut(out.path)}\n`);
    }
  }

  const realEndTime = performance.now();

  const time = Math.round(endTime - startTime);
  const realTime = Math.round(realEndTime - realStartTime);

  outs.print(chalk.greenBright(`Built in ${time}ms (${realTime}ms). \n`));

  return {
    stdouts: outs,
    result: {
      time,
      realTime,
    },
  };
}

function genFileOut(path: string): string {
  const ext = basename(path).split(".").at(-1)!;

  return colors[ext](`dist/${path.split("/dist/")[1]}`);
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

function concatPlugins(
  config: BuildConfig,
  plugins: NonNullable<BuildConfig["plugins"]>,
): BuildConfig {
  return {
    ...config,
    plugins: (config.plugins ?? []).concat(plugins),
  };
}
