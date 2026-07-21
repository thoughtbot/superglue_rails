import * as esbuild from 'esbuild'
import { default as importGlob } from 'esbuild-plugin-import-glob'
const importGlobPlugin = importGlob.default

const isWatch = process.argv.includes('--watch')

const buildOptions = {
  entryPoints: ['app/javascript/server_rendering.jsx'],
  bundle: true,
  sourcemap: true,
  outfile: 'app/assets/builds/server_rendering.js',
  platform: 'browser',
  logLevel: 'info',
  inject: ['./shim.js'],
  plugins: [importGlobPlugin()],
}

if (isWatch) {
  const ctx = await esbuild.context(buildOptions)
  await ctx.watch()
  console.log('Watching SSR for changes...')
} else {
  await esbuild.build(buildOptions)
}
