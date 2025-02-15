import type { BuildConfig } from "bun";

/**
 * Used to print to stdout and stderr because console outputs shuld be passed to zig components.
 * Internal, do not use.
 */
export class StdOuts {
  #stdout = "";
  #stderr = "";

  print(out: string) {
    this.out = out;
  }

  error(out: string) {
    this.err = out;
  }

  get out(): string {
    return this.#stdout;
  }

  set out(out: string) {
    this.#stdout += out;
  }

  get err(): string {
    return this.#stderr;
  }

  set err(out: string) {
    this.#stderr += out;
  }
}

/**
 * Default export in bundler.config.ts should be this type.
 * It's needed because by default bun's config requires an entrypoint, but a default is set elseware so it should be optional in this case.
 */
export type BundlerConfig = Partial<BuildConfig>;
