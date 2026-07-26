// @ts-ignore
import * as pages from '../views/**/*.{tsx,jsx}'

const pageIdentifierToPageComponent: Record<string, React.ComponentType> = {}

for (let i = 0; i < pages.filenames.length; i++) {
  const identifier = pages.filenames[i]
    .replace('../views/', '')
    .split('.')[0]
  pageIdentifierToPageComponent[identifier] = pages.default[i].default
}

export { pageIdentifierToPageComponent }
