# @lush/plugin-postcss

[![JSR](https://jsr.io/badges/@lush/plugin-postcss)](https://jsr.io/@lush/plugin-postcss)

Bun plugin for the lush framework to use postcss.

## Usage

```ts
import { postcss } from "@lush/plugin-postcss";

Bun.build({
  plugins: [
    postcss(
      [
        /* Your plugins */
      ],
      {
        /* Optionals */
      },
    ),
  ],
});
```
