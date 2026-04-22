import { asObject as pages } from '../views/**/*.tsx'

const pageIdentifierToPageComponent: Record<string, React.ComponentType> = {}

for (const key in pages) {
  const identifier = key.split('.')[0]
  pageIdentifierToPageComponent[identifier] = (pages[key] as { default: React.ComponentType }).default
}

export { pageIdentifierToPageComponent }
