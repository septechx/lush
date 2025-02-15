import { build, getConfig } from "./bundler";
import { StdOuts } from ".";

const config = await getConfig("bundler.config.ts");
build(true, config).then(write);

function write(outs: StdOuts) {
  process.stdout.write(outs.out);
  process.stderr.write(outs.err);
}
