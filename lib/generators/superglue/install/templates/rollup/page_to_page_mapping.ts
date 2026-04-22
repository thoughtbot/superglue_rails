const pageIdentifierToPageComponent: Record<string, React.ComponentType> = {}
const pages = import.meta.glob('../views/**/*.tsx', { eager: true })

for (const key in pages) {
  const identifier = key.replace('../views/', '').split('.')[0]
  pageIdentifierToPageComponent[identifier] = (pages[key] as { default: React.ComponentType }).default
}

export { pageIdentifierToPageComponent }
