import * as esbuild from 'esbuild'
import { watch } from 'fs'
import { default as importGlob } from 'esbuild-plugin-import-glob'
const importGlobPlugin = importGlob.default
import { esbuild as deepkitPlugin } from '@thoughtbot/superglue/deepkit'

const isWatch = process.argv.includes('--watch')

const buildOptions = {
  entryPoints: [
    'app/javascript/application.tsx',
  ],
  bundle: true,
  sourcemap: true,
  format: 'esm',
  outdir: 'app/assets/builds',
  publicPath: '/assets',
  plugins: process.env.NODE_ENV === 'production' ? [importGlobPlugin()] : [importGlobPlugin(), deepkitPlugin()],
  metafile: true,
  conditions: process.env.NODE_ENV === 'production' ? ['production'] : [],
}

if (isWatch) {
  let ctx = await esbuild.context(buildOptions)
  await ctx.watch()
  console.log('Watching for changes...')

  watch('app/views', { recursive: true }, async (event, filename) => {
    if (event === 'rename' && /\.[jt]sx$/.test(filename)) {
      await ctx.dispose()
      ctx = await esbuild.context(buildOptions)
      await ctx.watch()
    }
  })
} else {
  const result = await esbuild.build(buildOptions)
  console.log(await esbuild.analyzeMetafile(result.metafile))
}
