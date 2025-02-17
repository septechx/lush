import { build, getConfig } from "./bundler";
import type { BuildResult } from "./bundler";

const config = await getConfig("bundler.config.ts");
build(false, config).then(write);

function write(outs: BuildResult) {
  process.stdout.write(outs.stdouts.out);
  process.stderr.write(outs.stdouts.err);
}
