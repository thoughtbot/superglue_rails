import * as pages from '../views/**/*.html.jsx'

const pageIdentifierToPageComponent = {}

for (let i = 0; i < pages.filenames.length; i++) {
  const identifier = pages.filenames[i]
    .replace('../views/', '')
    .split('.')[0]
  pageIdentifierToPageComponent[identifier] = pages.default[i].default
}

export { pageIdentifierToPageComponent }
