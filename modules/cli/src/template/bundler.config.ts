import type { BuildConfig } from "bun";

import autoprefixer from "autoprefixer";
import tailwind from "@tailwindcss/postcss";
import { postcss } from "@lush/plugin-postcss";

export default {
  entrypoints: ["./app/index.html"],
  outdir: "./dist",
  splitting: true,
  env: "PUBLIC_*",
  sourcemap: "linked",
  plugins: [postcss([autoprefixer, tailwind])],
} as BuildConfig;
