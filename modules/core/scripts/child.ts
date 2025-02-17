import { build, getConfig } from "./bundler";
import { stringify } from "./lon";
import type { BuildResult } from "./bundler";

import fs from "fs";

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

function write(outs: BuildResult) {
  let buf = outs.stdouts.out;

  process.stderr.write(outs.stdouts.err);

  const lon = stringify(outs.result);
  buf += `%${lon}$`;

  fs.writeFileSync("temp.lon", lon);

  process.stdout.write(buf);
}
