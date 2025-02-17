import fs from "fs/promises";
import path from "path";
import type { BunPlugin } from "bun";

const LuaPlugin: BunPlugin = {
  name: "@lush/lush/lua-plugin",
  setup(build) {
    build.onStart(async () => {
      const directories = build.config.entrypoints.map((file) =>
        path.dirname(file),
      );

      const mappings = await Promise.all(
        directories.map(async (dir) => {
          const files = await fs.readdir(dir, { recursive: true });

          return files
            .filter((file) => file.endsWith(".lua"))
            .map((file) => ({
              from: path.join("src/routes", path.basename(file)),
              to: path.join("dist/client", path.basename(file)),
            }));
        }),
      );

      const flatMappings = mappings.flat();

      await Promise.all(
        flatMappings.map(async ({ from, to }) => {
          await fs.mkdir(path.dirname(to), { recursive: true });
          return fs.copyFile(from, to);
        }),
      );
    });
  },
};

export { LuaPlugin as lua };
