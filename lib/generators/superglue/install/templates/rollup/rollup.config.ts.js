import path from "path"
import resolve from "@rollup/plugin-node-resolve"
import commonjs from "@rollup/plugin-commonjs"
import babel from "@rollup/plugin-babel"
import alias from "@rollup/plugin-alias"
import importMetaGlob from "rollup-plugin-import-meta-glob"

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
    resolve({ extensions: [".ts", ".tsx", ".js", ".jsx"] }),
    commonjs(),
    babel({
      babelHelpers: "bundled",
      presets: [
        ["@babel/preset-react", { runtime: "automatic" }],
        "@babel/preset-typescript"
      ],
      extensions: [".ts", ".tsx", ".js", ".jsx"]
    }),
    importMetaGlob(),
  ]
}
