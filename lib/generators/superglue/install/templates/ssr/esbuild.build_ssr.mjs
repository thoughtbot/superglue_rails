import * as esbuild from 'esbuild'
import { watch } from 'fs'
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
  loader: {
    '.svg': 'dataurl',
  },
  inject: ['./shim.js'],
  plugins: [importGlobPlugin()],
}

if (isWatch) {
  let ctx = await esbuild.context(buildOptions)
  await ctx.watch()
  console.log('Watching SSR for changes...')

  watch('app/views', { recursive: true }, async (event, filename) => {
    if (event === 'rename' && /\.[jt]sx$/.test(filename)) {
      await ctx.dispose()
      ctx = await esbuild.context(buildOptions)
      await ctx.watch()
    }
  })
} else {
  await esbuild.build(buildOptions)
}
