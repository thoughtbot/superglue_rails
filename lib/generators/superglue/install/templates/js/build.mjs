import * as esbuild from 'esbuild'
import { default as importGlob } from 'esbuild-plugin-import-glob'
const importGlobPlugin = importGlob.default

const isWatch = process.argv.includes('--watch')

const buildOptions = {
  entryPoints: [
    'app/javascript/application.jsx',
  ],
  bundle: true,
  sourcemap: true,
  format: 'esm',
  outdir: 'app/assets/builds',
  publicPath: '/assets',
  plugins:  process.env.NODE_ENV === 'production' ? [importGlobPlugin()] : [importGlobPlugin()] ,
  metafile: true,
  conditions: process.env.NODE_ENV === 'production' ? ['production'] : [],
}

if (isWatch) {
  const ctx = await esbuild.context(buildOptions)
  await ctx.watch()
  console.log('Watching for changes...')
} else {
  const result = await esbuild.build(buildOptions)
  console.log(await esbuild.analyzeMetafile(result.metafile))
}