import path from "path"
import resolve from "@rollup/plugin-node-resolve"
import commonjs from "@rollup/plugin-commonjs"
import babel from "@rollup/plugin-babel"
import alias from "@rollup/plugin-alias"
import replace from "@rollup/plugin-replace"
import importMetaGlob from "rollup-plugin-import-meta-glob"

export default {
  input: "app/javascript/server_rendering.jsx",
  output: {
    file: "app/assets/builds/server_rendering.js",
    format: "iife",
    name: "SSR",
    inlineDynamicImports: true,
    sourcemap: true,
  },
  plugins: [
    replace({
      preventAssignment: true,
      'process.env.NODE_ENV': JSON.stringify('production')
    }),
    alias({
      entries: [
        { find: "@javascript", replacement: path.resolve("app/javascript") },
        { find: "@views", replacement: path.resolve("app/views") }
      ]
    }),
    resolve({
      extensions: [".js", ".jsx", ".ts", ".tsx"],
      browser: true,
      exportConditions: ["browser"]
    }),
    commonjs(),
    babel({
      babelHelpers: "bundled",
      presets: [["@babel/preset-react", { runtime: "automatic" }]],
      extensions: [".js", ".jsx", ".ts", ".tsx"]
    }),
    importMetaGlob(),
  ]
}
