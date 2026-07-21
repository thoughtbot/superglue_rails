Humid.configure do |config|
  # Path to your SSR build file located in `app/assets/builds/`.
  # Use a separate build from your client-side `application.js`.
  #
  # Required
  config.application_path = Rails.root.join("app/assets/builds/server_rendering.js")

  # Path to your source map file
  #
  # Optional
  config.source_map_path = Rails.root.join("app/assets/builds/server_rendering.js.map")

  # Raise errors if JS rendering failed. If false, the error will be
  # logged and Humid.render will return an empty string.
  #
  # Defaults to true.
  config.raise_render_errors = Rails.env.local?

  # The logger instance.
  # `console.log` and friends (`warn`, `error`) are delegated to
  # the respective logger levels on the ruby side.
  #
  # Defaults to nil
  config.logger = Rails.env.local? ? Rails.logger : nil
end

if Rails.env.local?
  # Use single_threaded mode for Spring and other forked envs.
  MiniRacer::Platform.set_flags! :single_threaded
  MINI_RACER_CONTEXT = MiniRacer::Context.new(timeout: 100, ensure_gc_after_idle: 2000)
end

# For production with puma, add to config/puma.rb:
#
#   on_worker_boot do
#     ctx = MiniRacer::Context.new(timeout: 1000, ensure_gc_after_idle: 2000)
#     MINI_RACER_CONTEXT = Humid.prepare(ctx)
#   end
#
#   on_worker_shutdown do
#     MINI_RACER_CONTEXT.dispose
#   end
#
# When SSR is enabled in production, you may also switch the client
# from `createRoot` to `hydrateRoot` so React attaches to the
# server-rendered markup instead of re-rendering:
#
#   // In application.tsx, change:
#   //   import { createRoot } from "react-dom/client"
#   //   const root = createRoot(appEl)
#   //   root.render(<App />)
#   //
#   // To:
#   //   import { hydrateRoot } from "react-dom/client"
#   //   hydrateRoot(appEl, <App />)
