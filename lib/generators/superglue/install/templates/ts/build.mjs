import * as esbuild from 'esbuild'
import deepkitType from './deepkit.mjs'

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
  plugins:  process.env.NODE_ENV === 'production' ? [] : [deepkitType()] ,
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