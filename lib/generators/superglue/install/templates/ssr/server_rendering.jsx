import React from "react";
import { createApp } from "@thoughtbot/superglue";
import { buildVisitAndRemote } from "./application_visit";
import { pageIdentifierToPageComponent } from "./page_to_page_mapping";
import { renderToString } from "react-dom/server";

require("source-map-support").install({
  retrieveSourceMap: (filename) => {
    return {
      url: filename,
      map: readSourceMap(filename),
    };
  },
});

setHumidRenderer((json, baseUrl, path) => {
  const initialState = JSON.parse(json);
  const { Provider, Outlet } = createApp({
    baseUrl,
    initialPage: initialState,
    path,
    buildVisitAndRemote,
    mapping: pageIdentifierToPageComponent,
  });

  return renderToString(
    <Provider>
      <Outlet />
    </Provider>,
  );
});
