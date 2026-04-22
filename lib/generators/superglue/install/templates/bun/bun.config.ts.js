import { globImportPlugin } from 'bun-plugin-glob-import'

const isWatch = process.argv.includes('--watch')

const config = {
  entrypoints: ['app/javascript/application.tsx'],
  outdir: 'app/assets/builds',
  sourcemap: 'external',
  plugins: [globImportPlugin()],
}

if (isWatch) {
  const { watch } = await import('fs')
  await Bun.build(config)
  console.log('Watching for changes...')

  watch('app/javascript', { recursive: true }, async () => {
    await Bun.build(config)
  })

  watch('app/views', { recursive: true }, async () => {
    await Bun.build(config)
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
