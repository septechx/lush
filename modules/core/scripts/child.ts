import { build, getConfig } from "./bundler";
import { StdOuts } from ".";

process.stdin.on("data", async (data) => {
  switch (data.toString()[0]) {
    case "b":
      const config = await getConfig("bundler.config.ts");
      build(true, config).then(write);
      break;
    default:
      process.stderr.write(`Unrecognized data: ${data.toString()}\m`);
  }
});

function write(outs: StdOuts) {
  process.stdout.write(outs.out);
  process.stderr.write(outs.err);
}
