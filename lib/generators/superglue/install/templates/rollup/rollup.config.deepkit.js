import path from "path"
import resolve from "@rollup/plugin-node-resolve"
import commonjs from "@rollup/plugin-commonjs"
import esbuild from "rollup-plugin-esbuild"
import alias from "@rollup/plugin-alias"
import importMetaGlob from "rollup-plugin-import-meta-glob"
import { rollup as deepkitPlugin } from "@thoughtbot/superglue/deepkit"

export default {
  input: "app/javascript/application.tsx",
  output: {
    file: "app/assets/builds/application.js",
    format: "esm",
    inlineDynamicImports: true,
    sourcemap: true
  },
  plugins: [
    alias({
      entries: [
        { find: "@javascript", replacement: path.resolve("app/javascript") },
        { find: "@views", replacement: path.resolve("app/views") }
      ]
    }),
    // @deepkit/type imports "buffer"; bundle the npm polyfill instead of
    // leaving it to a Node built-in the browser does not have.
    resolve({ extensions: [".ts", ".tsx", ".js", ".jsx"], preferBuiltins: false }),
    commonjs(),
    // Before esbuild: it rewrites the TypeScript source, and esbuild compiles
    // its output (rollup runs plugins in order and ignores `enforce`).
    ...(process.env.NODE_ENV === 'production' ? [] : [deepkitPlugin()]),
    esbuild({ jsx: "automatic" }),
    importMetaGlob(),
  ]
}
