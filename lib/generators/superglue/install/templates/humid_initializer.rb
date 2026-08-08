Humid.configure do |config|
  # Path to a JavaScript file to eval into the MiniRacer context before
  # the SSR bundle. Provides globals that bare V8 doesn't have
  # (TextEncoder, URL, MessageChannel, source-map-support, etc.).
  #
  # Required for SSR
  config.prepend = Rails.root.join("shim.js")

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
  MiniRacer::Platform.set_flags! :single_threaded
  MINI_RACER_SSR = { context: MiniRacer::Context.new(timeout: 1000, ensure_gc_after_idle: 2000) }

  ssr_checker = ActiveSupport::FileUpdateChecker.new([Humid.config.application_path.to_s]) do
    MINI_RACER_SSR[:context].dispose
    MINI_RACER_SSR[:context] = MiniRacer::Context.new(timeout: 1000, ensure_gc_after_idle: 2000)
  end

  Rails.application.reloaders << ssr_checker
  Rails.application.reloader.to_run do
    ssr_checker.execute_if_updated
  end
end
