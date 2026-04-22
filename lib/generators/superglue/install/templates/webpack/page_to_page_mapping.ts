const pageIdentifierToPageComponent: Record<string, React.ComponentType> = {}
const context = require.context('../views', true, /\.tsx$/)

context.keys().forEach((key: string) => {
  const identifier = key.replace('./', '').split('.')[0]
  pageIdentifierToPageComponent[identifier] = context(key).default
})

export { pageIdentifierToPageComponent }
