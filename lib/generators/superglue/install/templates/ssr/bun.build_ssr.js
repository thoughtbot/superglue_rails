import { readFileSync } from 'fs'

const shimCode = readFileSync('./shim.js', 'utf8')

await Bun.build({
  entrypoints: ['app/javascript/server_rendering.jsx'],
  outdir: 'app/assets/builds',
  sourcemap: 'external',
  target: 'browser',
  naming: 'server_rendering.js',
  define: {
    'process.env.NODE_ENV': JSON.stringify('production'),
  },
  banner: shimCode,
})
