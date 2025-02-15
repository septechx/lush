import autoprefixer from "autoprefixer";
import tailwind from "@tailwindcss/postcss";
import { postcss } from "@lush/plugin-postcss";
import type { BundlerConfig } from "@lush/lush";

export default {
  plugins: [postcss([autoprefixer, tailwind])],
} as BundlerConfig;
