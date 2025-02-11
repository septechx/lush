import type { BuildConfig } from "bun";

import autoprefixer from "autoprefixer";
// @ts-ignore
import tailwind from "@tailwindcss/postcss";
// @ts-ignore
import { postcss } from "@lush/plugin-postcss";

export default {
  entrypoints: ["./app/index.html"],
  outdir: "./dist",
  splitting: true,
  env: "PUBLIC_*",
  sourcemap: "linked",
  plugins: [postcss([autoprefixer, tailwind])],
} as BuildConfig;

