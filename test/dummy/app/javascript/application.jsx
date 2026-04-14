import React from "react"
import { createRoot } from "react-dom/client"
import { createApp } from "@thoughtbot/superglue"
import { createConsumer } from "@rails/actioncable"
import { buildVisitAndRemote } from "./application_visit"
import { pageIdentifierToPageComponent } from "./page_to_page_mapping"
import { Layout } from "./components"

if (typeof window !== "undefined") {
  document.addEventListener("DOMContentLoaded", function() {
    const appEl = document.getElementById("app")
    const location = window.location

    if (appEl) {
      const { Provider, Outlet, ujs } = createApp({
        baseUrl: location.origin,
        initialPage: window.SUPERGLUE_INITIAL_PAGE_STATE,
        path: location.pathname + location.search + location.hash,
        buildVisitAndRemote,
        mapping: pageIdentifierToPageComponent,
        cable: createConsumer(),
      })

      const root = createRoot(appEl)
      root.render(
        <div onClick={ujs.onClick} onSubmit={ujs.onSubmit}>
          <Provider>
            <Layout>
              <Outlet />
            </Layout>
          </Provider>
        </div>
      )
    }
  })
}
