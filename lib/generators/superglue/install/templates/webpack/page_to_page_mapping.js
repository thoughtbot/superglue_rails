const pageIdentifierToPageComponent = {}
const context = require.context('../views', true, /\.jsx$/)

context.keys().forEach((key) => {
  const identifier = key.replace('./', '').split('.')[0]
  pageIdentifierToPageComponent[identifier] = context(key).default
})

export { pageIdentifierToPageComponent }
