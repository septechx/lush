# @lush/plugin-postcss

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
