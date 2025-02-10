import { type BunPlugin } from "bun";
import fs from "fs/promises";
import postcss from "postcss";

type Opts = {
  from?: string;
  to?: string;
  syntax?: postcss.Syntax;
  parser?: postcss.Parser;
  stringifier?: postcss.Stringifier;
  map?: postcss.SourceMapOptions;
};

const PostcssPlugin: (
  plugins: postcss.AcceptedPlugin[],
  opts: Opts,
) => BunPlugin = (plugins, opts) => ({
  name: "lush-plugin-postcss",
  setup(build) {
    build.onLoad({ filter: /\b\w+\.css\b/ }, async (args) => {
      const input = await Bun.file(args.path).text();

      const processed = (await postcss(plugins)
        .process(input, {
          from: opts.from ?? args.path,
          to: opts.to ?? args.path,
          syntax: opts.syntax,
          parser: opts.parser,
          stringifier: opts.stringifier,
          map: opts.map,
        })
        .catch((error) => {
          if (error.name === "CssSyntaxError") {
            process.stderr.write(error.message + error.showSourceCode());
          } else {
            throw error;
          }
        }))!;

      processed.warnings().forEach((warn) => {
        process.stderr.write(warn.toString());
      });

      if (processed.map) {
        await fs.writeFile(opts.to + ".map", processed!.map.toString());
      }

      return {
        loader: "css",
        contents: processed.css,
      };
    });
  },
});

export { PostcssPlugin as postcss };
