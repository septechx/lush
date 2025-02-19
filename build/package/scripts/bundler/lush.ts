import path from "path";
import fs from "fs/promises";
import type { BunPlugin } from "bun";

const LushPlugin: BunPlugin = {
  name: "@lush/lush",
  setup(build) {
    build.onResolve({ filter: /.css$/ }, async (args) => {
      const stylesPath = path.join("src/styles", args.path);
      try {
        await fs.access(stylesPath);
        return { path: await fs.realpath(stylesPath) };
      } catch {
        return;
      }
    });

    build.onResolve({ filter: /.*/ }, async (args) => {
      const publicPath = path.join("public", args.path);
      try {
        await fs.access(publicPath);
        return { path: await fs.realpath(publicPath) };
      } catch {
        return;
      }
    });
  },
};

export { LushPlugin as lush };
