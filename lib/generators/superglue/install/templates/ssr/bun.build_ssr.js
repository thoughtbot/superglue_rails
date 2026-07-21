import { readFileSync, watch, existsSync } from 'fs'

const isWatch = process.argv.includes('--watch')

const shimCode = readFileSync('./shim.js', 'utf8')
const configFile = existsSync('./tsconfig.json') ? './tsconfig.json' : './jsconfig.json'
const config = JSON.parse(readFileSync(configFile, 'utf8'))
const watchDirs = config.include.map(p => p.replace(/\/?\*.*$/, ''))

const buildOptions = {
  entrypoints: ['app/javascript/server_rendering.jsx'],
  outdir: 'app/assets/builds',
  sourcemap: 'external',
  target: 'browser',
  naming: 'server_rendering.js',
  define: {
    'process.env.NODE_ENV': JSON.stringify('production'),
  },
  banner: shimCode,
}

if (isWatch) {
  await Bun.build(buildOptions)
  console.log('Watching SSR for changes...')

  for (const dir of watchDirs) {
    watch(dir, { recursive: true }, async () => {
      await Bun.build(buildOptions)
    })
  }
} else {
  const result = await Bun.build(buildOptions)

  if (!result.success) {
    console.error('SSR build failed')
    for (const log of result.logs) {
      console.error(log)
    }
    process.exit(1)
  }
}
