import {
  ApplicationRemote,
  ApplicationVisit,
  BuildVisitAndRemote,
} from "@thoughtbot/superglue";

/**
 * This function returns a wrapped visit and remote that will be used by UJS,
 * the Navigation component, and passed to your page components through the
 * NavigationContext.
 *
 * You can customize both functions to your liking. For example, for a progress
 * bar. This file also adds support for data-sg-remote.
 */
export const buildVisitAndRemote: BuildVisitAndRemote = ({
  navigateTo,
  visit,
  remote,
}) => {
  const appRemote: ApplicationRemote = (path, { dataset, ...options } = {}) => {
    /**
     * You can make use of `dataset` to add custom UJS options.
     * If you are implementing a progress bar, you can selectively
     * hide it for some links. For example:
     *
     * ```
     * <a href="/posts?props_at=data.header" data-sg-remote data-sg-hide-progress>
     *   Click me
     * </a>
     * ```
     *
     * This would be available as `sgHideProgress` on the dataset
     */
    return remote(path, options).then((result) => {
      if (result.hasError) {
        const { response } = result;

        if (response.status >= 400 && response.status < 500) {
          window.location.href = "/400.html";
        } else if (response.status >= 500) {
          window.location.href = "/500.html";
        }
      }

      return result;
    });
  };

  const appVisit: ApplicationVisit = (path, { dataset, ...options } = {}) => {
    /**
     * Do something before we make a request.
     * e.g, show a [progress bar](https://thoughtbot.github.io/superglue/recipes/progress-bar/).
     */
    return visit(path, options)
      .then((result) => {
        if (result.hasError) {
          const { response } = result;

          if (response.status >= 400 && response.status < 500) {
            window.location.href = "/400.html";
          } else if (response.status >= 500) {
            window.location.href = "/500.html";
          }

          return result;
        }

        /**
         * Your first expanded UJS option, `data-sg-replace`
         *
         * This option overrides the `navigationAction` to allow a link click or
         * a form submission to replace history instead of the usual push.
         */
        const navigationAction = !!dataset?.sgReplace
          ? "replace"
          : result.navigationAction;
        navigateTo(result.pageKey, {
          action: navigationAction,
        });

        return result;
      })
      .finally(() => {
        /**
         * Do something after a request.
         *
         * This is where you hide a progress bar.
         */
      });
  };

  return { visit: appVisit, remote: appRemote };
};
