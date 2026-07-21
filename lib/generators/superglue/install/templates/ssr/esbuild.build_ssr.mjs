import * as esbuild from 'esbuild'

await esbuild.build({
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
  plugins: [],
})
