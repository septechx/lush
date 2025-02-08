import { type BunPlugin } from "bun";
import postcss from "postcss";

const PostcssPlugin: (plugins: postcss.AcceptedPlugin[]) => BunPlugin = (
  plugins,
) => ({
  name: "Postcss plugin",
  setup(build) {
    build.onLoad({ filter: /styles.css/ }, async (args) => {
      const input = await Bun.file(args.path).text();

      const processed = await postcss(plugins).process(input, {
        from: args.path,
      });

      return {
        loader: "css",
        contents: processed.css,
      };
    });
  },
});

export { PostcssPlugin as postcss };
