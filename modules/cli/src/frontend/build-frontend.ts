import autoprefixer from "autoprefixer";
// @ts-ignore
import tailwind from "@tailwindcss/postcss";
import { postcss } from "./postcss-plugin";

const startTime = performance.now();
console.log("Building client");

await Bun.build({
  entrypoints: ["./app/index.html"],
  outdir: "./dist",
  splitting: true,
  env: "PUBLIC_*",
  sourcemap: "linked",
  plugins: [postcss([autoprefixer, tailwind])],
}).catch((e) => {
  console.error("Build failed");
  throw e;
});

const endTime = performance.now();
console.log(`Client built, took ${Math.round(endTime - startTime)}ms`);
