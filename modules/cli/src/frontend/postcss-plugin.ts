import { type BunPlugin } from "bun";
import postcss from "postcss";

const PostcssPlugin: (plugins: postcss.AcceptedPlugin[]) => BunPlugin = (
  plugins,
) => ({
  name: "Postcss plugin",
  setup(build) {
    build.onLoad({ filter: /styles.css/ }, async (args) => {
      const input = await Bun.file(args.path).text();

      const destSplit = args.path.split("/");
      destSplit.pop();
      destSplit.push("styles.gen.css");
      const dest = destSplit.join("/");

      const processed = await postcss(plugins).process(input, {
        from: args.path,
        to: dest,
      });

      await Bun.write(Bun.file(dest), processed.css);
    });
  },
});

export { PostcssPlugin as postcss };
