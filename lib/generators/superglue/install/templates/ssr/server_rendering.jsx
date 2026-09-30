import { createApp } from "@thoughtbot/superglue";
import { buildVisitAndRemote } from "./application_visit";
import { pageIdentifierToPageComponent } from "./page_to_page_mapping";
import { renderToString } from "react-dom/server";
import { Layout } from "./components";

setHumidRenderer((json, baseUrl, path) => {
  const initialState = JSON.parse(json);
  const { Provider, Outlet, ujs } = createApp({
    baseUrl,
    initialPage: initialState,
    path,
    buildVisitAndRemote,
    mapping: pageIdentifierToPageComponent,
  });

  return renderToString(
    <div onClick={ujs.onClick} onSubmit={ujs.onSubmit}>
      <Provider>
        <Layout>
          <Outlet />
        </Layout>
      </Provider>
    </div>
  );
});
