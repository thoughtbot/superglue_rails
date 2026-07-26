import { readFileSync, watch } from 'fs'

const isWatch = process.argv.includes('--watch')

const shimCode = readFileSync('./shim.js', 'utf8')
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

  watch('app/views', { recursive: true }, async (event, filename) => {
    if (event === 'rename' && /\.[jt]sx$/.test(filename)) {
      await Bun.build(buildOptions)
    }
  })
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
