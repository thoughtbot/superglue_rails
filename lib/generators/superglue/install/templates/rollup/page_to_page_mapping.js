const pageIdentifierToPageComponent = {}
const pages = import.meta.glob('../views/**/*.{tsx,jsx}', { eager: true })

for (const key in pages) {
  const identifier = key.replace('../views/', '').split('.')[0]
  pageIdentifierToPageComponent[identifier] = pages[key].default
}

export { pageIdentifierToPageComponent }
