import { tailwind } from "./tailwind-plugin";

Bun.build({
  entrypoints: ["./app/index.html"],
  outdir: "./dist",
  splitting: true,
  env: "PUBLIC_*",
  sourcemap: "linked",
  plugins: [tailwind],
});
