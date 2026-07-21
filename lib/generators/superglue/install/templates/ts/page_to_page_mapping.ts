// @ts-ignore
import * as pages from '../views/**/*.html.tsx'

const pageIdentifierToPageComponent: Record<string, React.ComponentType> = {}

for (let i = 0; i < pages.filenames.length; i++) {
  const identifier = pages.filenames[i]
    .replace('../views/', '')
    .split('.')[0]
  pageIdentifierToPageComponent[identifier] = pages.default[i].default
}

export { pageIdentifierToPageComponent }
