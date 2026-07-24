import React from "react";
import { createRoot, hydrateRoot } from "react-dom/client";
import { createApp, SaveResponse } from "@thoughtbot/superglue";
import { buildVisitAndRemote } from "./application_visit";
import { pageIdentifierToPageComponent } from "./page_to_page_mapping";
import { Layout } from "./components";

declare global {
  interface Window {
    SUPERGLUE_INITIAL_PAGE_STATE: SaveResponse;
  }
}

if (typeof window !== "undefined" && window.SUPERGLUE_INITIAL_PAGE_STATE) {
  document.addEventListener("DOMContentLoaded", function () {
    const appEl = document.getElementById("app");
    const location = window.location;

    if (appEl) {
      const { Provider, Outlet, ujs } = createApp({
        // The base url prefixed to all calls made by `visit` and `remote`.
        baseUrl: location.origin,
        // The global var SUPERGLUE_INITIAL_PAGE_STATE is set by your erb
        // template, e.g., index.html.erb
        initialPage: window.SUPERGLUE_INITIAL_PAGE_STATE,
        // The initial path of the page, e.g., /foobar
        path: location.pathname + location.search + location.hash,
        // Callback used to setup visit and remote
        buildVisitAndRemote,
        // Mapping between the page identifier to page component
        mapping: pageIdentifierToPageComponent,
      });

      const app = (
        <div onClick={ujs.onClick} onSubmit={ujs.onSubmit}>
          <Provider>
            <Layout>
              <Outlet />
            </Layout>
          </Provider>
        </div>
      );

      if (appEl.hasChildNodes()) {
        hydrateRoot(appEl, app);
      } else {
        createRoot(appEl).render(app);
      }
    }
  });
}
