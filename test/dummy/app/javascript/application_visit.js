export const buildVisitAndRemote = ({ navigateTo, visit, remote }) => {
  const appRemote = (path, { dataset, ...options } = {}) => {
    return remote(path, options).then(result => {
      if (result.hasError) {
        const { response } = result

        if (response.status >= 400 && response.status < 500) {
          window.location.href = "/400.html"
        } else if (response.status >= 500) {
          window.location.href = "/500.html"
        }
      }

      return result
    })
  }

  const appVisit = (path, { dataset, ...options } = {}) => {
    return visit(path, options)
      .then(result => {
        if (result.hasError) {
          const { response } = result

          if (response.status >= 400 && response.status < 500) {
            window.location.href = "/400.html"
          } else if (response.status >= 500) {
            window.location.href = "/500.html"
          }

          return result
        }

        const navigationAction = !!dataset?.sgReplace
          ? "replace"
          : result.navigationAction
        navigateTo(result.pageKey, {
          action: navigationAction
        })

        return result
      })
  }

  return { visit: appVisit, remote: appRemote }
}
