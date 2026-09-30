import { globImportPlugin } from 'bun-plugin-glob-import'
// Bun's adapter is its own entry point; the main export has no `bun`.
import ttscPlugin from '@ttsc/unplugin/bun'
import { watch } from 'fs'

const isWatch = process.argv.includes('--watch')

const config = {
  entrypoints: ['app/javascript/application.tsx'],
  outdir: 'app/assets/builds',
  sourcemap: 'external',
  jsx: { runtime: 'automatic' },
  plugins: [
    globImportPlugin(),
    ...(process.env.NODE_ENV === 'production' ? [] : [ttscPlugin()])
  ],
}

if (isWatch) {
  await Bun.build(config)
  console.log('Watching for changes...')

  watch('app/views', { recursive: true }, async (event, filename) => {
    if (event === 'rename' && /\.[jt]sx$/.test(filename)) {
      await Bun.build(config)
    }
  })
} else {
  const result = await Bun.build(config)

  if (!result.success) {
    console.error('Build failed')
    for (const log of result.logs) {
      console.error(log)
    }
    process.exit(1)
  }
}
