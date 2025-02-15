import fs from "fs/promises";
import { BundlerConfig } from "..";

export async function getConfig(path: string) {
  const realPath = await fs.realpath(path);
  return await import(realPath).then(
    (d: { default: BundlerConfig }) => d.default,
  );
}
