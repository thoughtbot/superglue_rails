import { asObject as pages } from '../views/**/*.html.jsx'

const pageIdentifierToPageComponent = {}

for (const key in pages) {
  const identifier = key.split('.')[0]
  pageIdentifierToPageComponent[identifier] = pages[key].default
}

export { pageIdentifierToPageComponent }
