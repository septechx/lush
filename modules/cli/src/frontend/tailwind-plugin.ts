import { $, type BunPlugin } from "bun";

export const tailwind: BunPlugin = {
  name: "Tailwind plugin",
  setup(build) {
    build.onResolve(
      { filter: /styles.css/, namespace: "file" },
      async (args) => {
        await $`bunx @tailwindcss/cli -i ./app/styles.css -o ./app/styles.gen.css`;
        return {
          path:
            args.resolveDir +
            args.path.replace("styles.css", "styles.gen.css").substring(1),
        };
      },
    );
  },
};
