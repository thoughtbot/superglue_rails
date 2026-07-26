const path = require("path")
const webpack = require("webpack")
const { webpack: ttscPlugin } = require("@ttsc/unplugin")

module.exports = {
  mode: "production",
  devtool: "source-map",
  entry: {
    application: "./app/javascript/application.tsx"
  },
  module: {
    rules: [
      {
        test: /\.[jt]sx?$/,
        exclude: /node_modules/,
        loader: "esbuild-loader",
        options: {
          target: "es2020"
        }
      }
    ]
  },
  resolve: {
    extensions: [".tsx", ".ts", ".jsx", ".js", ".json", ".wasm"],
    alias: {
      "@javascript": path.resolve(__dirname, "app/javascript"),
      "@views": path.resolve(__dirname, "app/views")
    }
  },
  output: {
    filename: "[name].js",
    sourceMapFilename: "[file].map",
    chunkFormat: "module",
    path: path.resolve(__dirname, "app/assets/builds"),
  },
  plugins: [
    new webpack.optimize.LimitChunkCountPlugin({
      maxChunks: 1
    }),
    ...(process.env.NODE_ENV === 'production' ? [] : [ttscPlugin()])
  ]
}
