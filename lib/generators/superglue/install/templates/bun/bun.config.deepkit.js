import { globImportPlugin } from 'bun-plugin-glob-import'
import { bun as deepkitPlugin } from '@thoughtbot/superglue/deepkit'
import { readFileSync, watch, existsSync } from 'fs'

const isWatch = process.argv.includes('--watch')

const configFile = existsSync('./tsconfig.json') ? './tsconfig.json' : './jsconfig.json'
const tsconfig = JSON.parse(readFileSync(configFile, 'utf8'))
const watchDirs = tsconfig.include.map(p => p.replace(/\/?\*.*$/, ''))

const config = {
  entrypoints: ['app/javascript/application.tsx'],
  outdir: 'app/assets/builds',
  sourcemap: 'external',
  plugins: [
    globImportPlugin(),
    ...(process.env.NODE_ENV === 'production' ? [] : [deepkitPlugin()])
  ],
}

if (isWatch) {
  await Bun.build(config)
  console.log('Watching for changes...')

  for (const dir of watchDirs) {
    watch(dir, { recursive: true }, async () => {
      await Bun.build(config)
    })
  }
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
