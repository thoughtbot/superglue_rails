require "json"
require "rails/generators/named_base"
require "rails/generators/resource_helpers"

module Superglue
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("../templates", __FILE__)

      class_option :typescript,
        type: :boolean,
        default: true,
        desc: "Use TypeScript. Pass --no-typescript for JavaScript."

      class_option :bundler,
        type: :string,
        required: false,
        desc: "JavaScript bundler to use (esbuild, bun, rollup, webpack). Defaults to the detected bundler."

      # A string default, rather than nil, lets `--no-validator` (which Thor
      # parses as nil) be told apart from leaving the option out.
      class_option :validator,
        type: :string,
        default: "auto",
        desc: "Runtime type validator to use (deepkit, typia). Pass --no-validator to skip it. " \
          "auto picks typia on TypeScript 7 or later (or when TypeScript is not installed yet) " \
          "and deepkit on TypeScript 6 or earlier."

      class_option :svgr,
        type: :boolean,
        default: true,
        desc: "Enable SVGR to import SVGs as React components. Pass --no-svgr to disable."

      def create_files
        remove_file "#{app_js_path}/application.js"

        resolve_choices
        say_choices

        if @use_typescript
          copy_ts_files
        else
          copy_js_files
        end

        copy_bundler_config
        update_build_script
        copy_page_to_page_mapping

        say "Copying Superglue initializer"
        copy_file "#{__dir__}/templates/initializer.rb", "config/initializers/superglue.rb"

        say "Copying Humid initializer"
        copy_file "#{__dir__}/templates/humid_initializer.rb", "config/initializers/humid.rb"

        copy_ssr_files

        say "Copying application.json.props"
        copy_file "#{__dir__}/templates/application.json.props", "app/views/layouts/application.json.props"

        say "Copying stream.json.props"
        copy_file "#{__dir__}/templates/stream.json.props", "app/views/layouts/stream.json.props"

        say "Adding initial page state and #app container to application.html.erb"
        update_application_layout

        say "Adding required member methods to ApplicationRecord"
        add_member_methods

        install_packages

        if @use_svgr
          configure_svgr
        end

        say "Superglue is Installed! 🎉", :green
      end

      private

      BUNDLERS = %w[esbuild bun rollup webpack].freeze
      VALIDATORS = %w[deepkit typia none].freeze

      def detect_bundler
        if File.exist?("webpack.config.js")
          "webpack"
        elsif File.exist?("rollup.config.js") || File.exist?("rollup.config.mjs")
          "rollup"
        elsif File.exist?("bun.config.js") || File.exist?("bun.config.mjs")
          "bun"
        elsif esbuild_detected?
          "esbuild"
        end
      end

      def esbuild_detected?
        return true if File.exist?("build.mjs")
        return false unless File.exist?("package.json")

        package_json = JSON.parse(File.read("package.json"))
        build_script = package_json.dig("scripts", "build") || ""
        dev_deps = package_json["devDependencies"] || {}

        build_script.include?("esbuild") || dev_deps.key?("esbuild")
      rescue JSON::ParserError
        false
      end

      # typia's ttsc toolchain needs TypeScript 7's native compiler, while
      # deepkit's type compiler needs the JavaScript compiler API that
      # TypeScript 7 removed.
      TYPIA_MIN_TYPESCRIPT = 7
      DEEPKIT_MAX_TYPESCRIPT = 6
      AUTO_VALIDATOR = "auto"

      def resolve_choices
        @bundler = resolve_bundler
        @use_typescript = options["typescript"]
        @typescript_major = detect_typescript_major
        @validator = resolve_validator
        @use_svgr = options["svgr"]
      end

      def resolve_bundler
        requested_bundler = options["bundler"]
        detected_bundler = detect_bundler

        if requested_bundler
          unless BUNDLERS.include?(requested_bundler)
            raise Thor::Error, "Unknown bundler '#{requested_bundler}'. Must be one of: #{BUNDLERS.join(", ")}"
          end

          requested_bundler
        elsif detected_bundler
          detected_bundler
        else
          say "No JavaScript bundler detected.", :red
          say "Install one first via jsbundling-rails:"
          say "  rails javascript:install:[esbuild|bun|rollup|webpack]"
          say "See: https://github.com/rails/jsbundling-rails"
          raise Thor::Error, "No bundler found. Install one via jsbundling-rails and re-run this generator."
        end
      end

      # The major version of the project's TypeScript: the installed package
      # first, then the range declared in package.json. nil when TypeScript is
      # not part of the project yet, or its range has no version (e.g. "latest").
      def detect_typescript_major
        installed_version = installed_typescript_version
        declared_range = declared_typescript_range
        version = installed_version || declared_range

        version.to_s[/\d+/]&.to_i
      end

      def installed_typescript_version
        manifest_path = "node_modules/typescript/package.json"

        if File.exist?(manifest_path)
          JSON.parse(File.read(manifest_path))["version"]
        end
      rescue JSON::ParserError
        nil
      end

      def declared_typescript_range
        if File.exist?("package.json")
          package_json = JSON.parse(File.read("package.json"))
          dependencies = (package_json["dependencies"] || {}).merge(package_json["devDependencies"] || {})
          dependencies["typescript"]
        end
      rescue JSON::ParserError
        nil
      end

      # --no-validator and --skip-validator arrive as nil; --validator=none
      # still works too.
      def resolve_validator
        requested_validator = options["validator"]
        validator_disabled = requested_validator.nil? || requested_validator == "none"
        validator_automatic = requested_validator == AUTO_VALIDATOR

        if validator_disabled
          "none"
        elsif validator_automatic
          @use_typescript ? default_validator : "none"
        elsif !@use_typescript
          raise Thor::Error, "--validator=#{requested_validator} requires TypeScript. Remove --no-typescript."
        else
          ensure_validator_supported(requested_validator)
          requested_validator
        end
      end

      def default_validator
        typescript_supports_typia = @typescript_major.nil? || @typescript_major >= TYPIA_MIN_TYPESCRIPT

        if typescript_supports_typia
          "typia"
        else
          "deepkit"
        end
      end

      def ensure_validator_supported(validator)
        typescript_detected = !@typescript_major.nil?
        typia_unsupported = validator == "typia" && typescript_detected && @typescript_major < TYPIA_MIN_TYPESCRIPT
        deepkit_unsupported = validator == "deepkit" && typescript_detected && @typescript_major > DEEPKIT_MAX_TYPESCRIPT

        if !VALIDATORS.include?(validator)
          raise Thor::Error, "Unknown validator '#{validator}'. Must be one of: #{VALIDATORS.join(", ")}"
        elsif typia_unsupported
          raise Thor::Error, "typia requires TypeScript #{TYPIA_MIN_TYPESCRIPT} or later, found TypeScript #{@typescript_major}"
        elsif deepkit_unsupported
          raise Thor::Error, "deepkit requires TypeScript #{DEEPKIT_MAX_TYPESCRIPT} or earlier, found TypeScript #{@typescript_major}"
        end
      end

      # The TypeScript package to install, or nil to keep the project's own.
      # Re-adding an existing typescript would upgrade it to the latest release.
      def typescript_package
        typescript_missing = @typescript_major.nil?

        if typescript_missing && @validator == "deepkit"
          "typescript@^#{DEEPKIT_MAX_TYPESCRIPT}"
        elsif typescript_missing
          "typescript@^#{TYPIA_MIN_TYPESCRIPT}"
        end
      end

      def say_choices
        bundler_source = options["bundler"] ? "from --bundler" : "detected"
        typescript_source = if @typescript_major
          "TypeScript #{@typescript_major} detected"
        else
          "will install #{typescript_package}"
        end
        validator_source = case options["validator"]
        when AUTO_VALIDATOR then typescript_source
        when nil then "from --no-validator"
        else "from --validator"
        end

        say ""
        say "Installing Superglue with:", :green
        say "  Bundler:    #{@bundler} (#{bundler_source}; change with --bundler)"
        if @use_typescript
          say "  TypeScript: yes (#{typescript_source}; --no-typescript for JavaScript)"
          say "  Validator:  #{@validator} (#{validator_source}; change with --validator=deepkit|typia or --no-validator)"
        else
          say "  TypeScript: no (--typescript to enable)"
        end
        say "  SVGR:       #{@use_svgr ? "yes (--no-svgr to disable)" : "no (--svgr to enable)"}"
        say ""
      end

      def update_build_script
        case @bundler
        when "esbuild"
          say "Updating build script for esbuild"
          run %(npm pkg set scripts.build="node build.mjs")
        when "rollup"
          say "Updating build script for rollup"
          run %(npm pkg set scripts.build="rollup -c rollup.config.js")
        end
      end

      def bundler_template_for(bundler_name, base_path, variants)
        if @use_typescript
          variant_key = variants.key?(@validator) ? @validator : "none"
          variants[variant_key]
        else
          base_path
        end
      end

      def copy_bundler_config
        case @bundler
        when "esbuild"
          template_name = bundler_template_for("esbuild", "js/build.mjs", {
            "deepkit" => "ts/build.deepkit.mjs",
            "typia" => "ts/build.typia.mjs",
            "none" => "ts/build.mjs"
          })
          say "Adding build.mjs for #{@use_typescript ? "TypeScript" : "JavaScript"} compilation"
          copy_file "#{__dir__}/templates/#{template_name}", "build.mjs"
        when "bun"
          template_name = bundler_template_for("bun", "bun/bun.config.js", {
            "deepkit" => "bun/bun.config.deepkit.js",
            "typia" => "bun/bun.config.typia.js",
            "none" => "bun/bun.config.ts.js"
          })
          say "Overwriting bun.config.js with Superglue configuration"
          copy_file "#{__dir__}/templates/#{template_name}", "bun.config.js"
        when "webpack"
          template_name = bundler_template_for("webpack", "webpack/webpack.config.js", {
            "deepkit" => "webpack/webpack.config.deepkit.js",
            "typia" => "webpack/webpack.config.typia.js",
            "none" => "webpack/webpack.config.ts.js"
          })
          say "Overwriting webpack.config.js with Superglue configuration"
          copy_file "#{__dir__}/templates/#{template_name}", "webpack.config.js"
        when "rollup"
          template_name = bundler_template_for("rollup", "rollup/rollup.config.js", {
            "deepkit" => "rollup/rollup.config.deepkit.js",
            "typia" => "rollup/rollup.config.typia.js",
            "none" => "rollup/rollup.config.ts.js"
          })
          say "Overwriting rollup.config.js with Superglue configuration"
          copy_file "#{__dir__}/templates/#{template_name}", "rollup.config.js"
        end
      end

      def copy_page_to_page_mapping
        ext = @use_typescript ? "ts" : "js"

        mapping_source = case @bundler
        when "esbuild"
          "#{ext}/page_to_page_mapping.#{ext}"
        when "bun"
          "bun/page_to_page_mapping.#{ext}"
        when "webpack"
          "webpack/page_to_page_mapping.#{ext}"
        when "rollup"
          "rollup/page_to_page_mapping.#{ext}"
        end

        say "Copying page_to_page_mapping.#{ext} for #{@bundler}"
        copy_file "#{__dir__}/templates/#{mapping_source}", "#{app_js_path}/page_to_page_mapping.#{ext}"
      end

      def install_packages
        say "Installing Superglue and friends"
        run "yarn add react react-dom @thoughtbot/superglue@^2.0.0-rc.2"

        if @use_typescript
          typescript_dev_packages = ["@types/react-dom", "@types/react", "@types/node", "@thoughtbot/candy_wrapper@0.0.4", typescript_package]
          run "yarn add -D #{typescript_dev_packages.compact.join(" ")}"
        end

        if @validator == "deepkit"
          say "Installing Deepkit for runtime type validation"
          run "yarn add -D @deepkit/type @deepkit/core @deepkit/type-compiler unplugin"
        elsif @validator == "typia"
          say "Installing Typia and ttsc for runtime type validation"
          run "yarn add -D typia ttsc @ttsc/unplugin"
        end

        case @bundler
        when "esbuild"
          say "Installing esbuild glob plugin"
          run "yarn add -D esbuild-plugin-import-glob"
        when "bun"
          say "Installing bun glob plugin"
          run "yarn add -D bun-plugin-glob-import"
        when "webpack"
          say "Installing esbuild-loader for JSX support"
          run "yarn add -D esbuild-loader"
        when "rollup"
          say "Installing rollup plugins for JSX, TypeScript, and glob support"
          run "yarn add -D rollup-plugin-esbuild esbuild @rollup/plugin-commonjs @rollup/plugin-alias @rollup/plugin-replace rollup-plugin-import-meta-glob"
        end

        say "Installing build dependencies"
        run "yarn add -D npm-run-all"
      end

      def copy_ts_files
        say "Copying application.tsx file to #{app_js_path}"
        copy_file "#{__dir__}/templates/ts/application.tsx", "#{app_js_path}/application.tsx"

        say "Copying flash.ts file to #{app_js_path}"
        copy_file "#{__dir__}/templates/ts/flash.ts", "#{app_js_path}/flash.ts"

        say "Copying application_visit.ts file to #{app_js_path}"
        copy_file "#{__dir__}/templates/ts/application_visit.ts", "#{app_js_path}/application_visit.ts"

        say "Copying components to #{app_js_path}"
        copy_file "#{__dir__}/templates/ts/inputs.tsx", "#{app_js_path}/components/Inputs.tsx"
        copy_file "#{__dir__}/templates/ts/layout.tsx", "#{app_js_path}/components/Layout.tsx"
        copy_file "#{__dir__}/templates/ts/components.ts", "#{app_js_path}/components/index.ts"

        say "Copying tsconfig.json"
        copy_file "#{__dir__}/templates/ts/tsconfig.json", "tsconfig.json"

        if @validator == "deepkit"
          say "Enabling Deepkit reflection in tsconfig.json"
          inject_into_file "tsconfig.json", before: /\n\}$/ do
            ",\n  \"reflection\": true"
          end
        elsif @validator == "typia"
          say "Adding Superglue typia plugin to tsconfig.json"
          inject_into_file "tsconfig.json", after: /"compilerOptions": \{/ do
            "\n    \"plugins\": [{ \"transform\": \"@thoughtbot/superglue/typia\" }],"
          end
        end
      end

      def copy_js_files
        say "Copying application.jsx file to #{app_js_path}"
        copy_file "#{__dir__}/templates/js/application.jsx", "#{app_js_path}/application.jsx"

        say "Copying flash.js file to #{app_js_path}"
        copy_file "#{__dir__}/templates/js/flash.js", "#{app_js_path}/flash.js"

        say "Copying application_visit.js file to #{app_js_path}"
        copy_file "#{__dir__}/templates/js/application_visit.js", "#{app_js_path}/application_visit.js"

        say "Copying components to #{app_js_path}"
        copy_file "#{__dir__}/templates/js/inputs.jsx", "#{app_js_path}/components/Inputs.jsx"
        copy_file "#{__dir__}/templates/js/layout.jsx", "#{app_js_path}/components/Layout.jsx"
        copy_file "#{__dir__}/templates/js/components.js", "#{app_js_path}/components/index.js"

        say "Copying jsconfig.json"
        copy_file "#{__dir__}/templates/js/jsconfig.json", "jsconfig.json"
      end

      def add_member_methods
        inject_into_file "app/models/application_record.rb", after: "class ApplicationRecord < ActiveRecord::Base\n" do
          <<-RUBY
  # This enables digging by index when used with props_template
  # see https://thoughtbot.github.io/superglue/digging/#index-based-selection
  def self.member_at(index)
    offset(index).limit(1).first
  end

  # This enables digging by attribute when used with props_template
  # see https://thoughtbot.github.io/superglue/digging/#attribute-based-selection
  def self.member_by(attr, value)
    find_by(Hash[attr, value])
  end
          RUBY
        end
      end

      def update_application_layout
        layout_path = "app/views/layouts/application.html.erb"

        inject_into_file layout_path, before: /^\s*<%= javascript_include_tag/ do
          <<-ERB

    <script type="text/javascript">
      window.SUPERGLUE_INITIAL_PAGE_STATE=<%= render_props %>;<%# erblint:disable ErbSafety %>
    </script>

          ERB
        end

        gsub_file layout_path, "<%= yield %>", '<div id="app"><%= yield %></div>'
      end

      def copy_ssr_files
        say "Adding ssr_context to ApplicationController"
        inject_into_file "app/controllers/application_controller.rb", after: "class ApplicationController < ActionController::Base\n" do
          "  ssr_context { Humid.prepare(MINI_RACER_SSR[:context]) if defined?(MINI_RACER_SSR) }\n"
        end

        say "Copying MiniRacer shim"
        copy_file "#{__dir__}/templates/ssr/shim.js", "shim.js"

        ssr_ext = @use_typescript ? "tsx" : "jsx"

        say "Copying SSR build script for #{@bundler}"
        case @bundler
        when "esbuild"
          copy_file "#{__dir__}/templates/ssr/esbuild.build_ssr.mjs", "build_ssr.mjs"
          gsub_file "build_ssr.mjs", "server_rendering.jsx", "server_rendering.#{ssr_ext}"
          run %(npm pkg set scripts.build:ssr="node build_ssr.mjs")
        when "bun"
          copy_file "#{__dir__}/templates/ssr/bun.build_ssr.js", "build_ssr.js"
          gsub_file "build_ssr.js", "server_rendering.jsx", "server_rendering.#{ssr_ext}"
          run %(npm pkg set scripts.build:ssr="bun run build_ssr.js")
        when "webpack"
          copy_file "#{__dir__}/templates/ssr/webpack.build_ssr.js", "webpack.config.ssr.js"
          gsub_file "webpack.config.ssr.js", "server_rendering.jsx", "server_rendering.#{ssr_ext}"
          run %(npm pkg set scripts.build:ssr="webpack --config webpack.config.ssr.js")
        when "rollup"
          copy_file "#{__dir__}/templates/ssr/rollup.build_ssr.config.js", "rollup.config.ssr.js"
          gsub_file "rollup.config.ssr.js", "server_rendering.jsx", "server_rendering.#{ssr_ext}"
          run %(npm pkg set scripts.build:ssr="rollup -c rollup.config.ssr.js")
        end

        if @validator != "none"
          say "Adding #{@validator} plugin to SSR build"
          add_validator_to_ssr_build
        end

        if @use_typescript
          say "Copying server_rendering.tsx"
          copy_file "#{__dir__}/templates/ssr/server_rendering.tsx", "#{app_js_path}/server_rendering.tsx"
        else
          say "Copying server_rendering.jsx"
          copy_file "#{__dir__}/templates/ssr/server_rendering.jsx", "#{app_js_path}/server_rendering.jsx"
        end

        say "Adding build:web, build:dev, and build:watch scripts"
        web_build = case @bundler
        when "esbuild" then "node build.mjs"
        when "bun" then "bun run bun.config.js"
        when "webpack" then "webpack --config webpack.config.js"
        when "rollup" then "rollup -c rollup.config.js"
        end

        run %(npm pkg set scripts.build:web="#{web_build}")
        run %(npm pkg set scripts.build="run-p 'build:web -- {@}' 'build:ssr -- {@}' --")
        run %(npm pkg set scripts.build:prod="NODE_ENV=production yarn build")

        if File.exist?("config/puma.rb")
          say "Adding MiniRacer SSR context to puma.rb for production"
          append_to_file "config/puma.rb" do
            <<~RUBY

              # Create a MiniRacer context for SSR on each worker boot.
              # MiniRacer is thread safe but not fork safe.
              if ENV["RAILS_ENV"] == "production"
                on_worker_boot do
                  MINI_RACER_SSR = { context: MiniRacer::Context.new(timeout: 1000, ensure_gc_after_idle: 2000) }
                end

                on_worker_shutdown do
                  MINI_RACER_SSR[:context].dispose if defined?(MINI_RACER_SSR)
                end
              end
            RUBY
          end
        end
      end

      def add_validator_to_ssr_build
        plugin_call = (@validator == "deepkit") ? "deepkitPlugin()" : "ttscPlugin()"
        dev_only_plugin = "...(process.env.NODE_ENV === 'production' ? [] : [#{plugin_call}])"
        plugin_import = ssr_validator_import

        case @bundler
        when "esbuild"
          inject_into_file "build_ssr.mjs", plugin_import, after: "const importGlobPlugin = importGlob.default\n"
          inject_into_file "build_ssr.mjs", "    #{dev_only_plugin},\n", after: "    importGlobPlugin(),\n"
        when "bun"
          inject_into_file "build_ssr.js", plugin_import, after: "import { globImportPlugin } from 'bun-plugin-glob-import'\n"
          gsub_file "build_ssr.js",
            "plugins: [globImportPlugin()],",
            "plugins: [\n    globImportPlugin(),\n    #{dev_only_plugin}\n  ],"
        when "webpack"
          inject_into_file "webpack.config.ssr.js", plugin_import, after: "const webpack = require(\"webpack\")\n"
          gsub_file "webpack.config.ssr.js", "    })\n  ]\n}", "    }),\n    #{dev_only_plugin}\n  ]\n}"
        when "rollup"
          inject_into_file "rollup.config.ssr.js", plugin_import, after: "import importMetaGlob from \"rollup-plugin-import-meta-glob\"\n"
          # Before esbuild: the validator rewrites the TypeScript source and
          # esbuild compiles its output. Rollup runs plugins in array order.
          inject_into_file "rollup.config.ssr.js", "    #{dev_only_plugin},\n", before: "    esbuild({ jsx: \"automatic\" }),\n"
        end
      end

      def ssr_validator_import
        case [@validator, @bundler]
        when ["deepkit", "esbuild"]
          "import { esbuild as deepkitPlugin } from '@thoughtbot/superglue/deepkit'\n"
        when ["deepkit", "bun"]
          "import { bun as deepkitPlugin } from '@thoughtbot/superglue/deepkit'\n"
        when ["deepkit", "webpack"]
          "const { webpack: deepkitPlugin } = require(\"@thoughtbot/superglue/deepkit\")\n"
        when ["deepkit", "rollup"]
          "import { rollup as deepkitPlugin } from \"@thoughtbot/superglue/deepkit\"\n"
        when ["typia", "esbuild"]
          "import ttsc from '@ttsc/unplugin'\nconst ttscPlugin = ttsc.esbuild\n"
        when ["typia", "bun"]
          "import ttscPlugin from '@ttsc/unplugin/bun'\n"
        when ["typia", "webpack"]
          "const ttscPlugin = require(\"@ttsc/unplugin\").default.webpack\n"
        when ["typia", "rollup"]
          "import ttsc from \"@ttsc/unplugin\"\nconst ttscPlugin = ttsc.rollup\n"
        end
      end

      def configure_svgr
        say "Configuring SVGR"

        case @bundler
        when "esbuild"
          run "yarn add -D esbuild-plugin-svgr"
          inject_svgr_esbuild("build.mjs")
          inject_svgr_esbuild("build_ssr.mjs")
        when "bun"
          run "yarn add -D esbuild-plugin-svgr"
          inject_svgr_bun
        when "webpack"
          run "yarn add -D @svgr/webpack"
          inject_svgr_webpack("webpack.config.js")
          inject_svgr_webpack("webpack.config.ssr.js")
        when "rollup"
          run "yarn add -D @svgr/rollup"
          inject_svgr_rollup("rollup.config.js")
          inject_svgr_rollup("rollup.config.ssr.js")
        end
      end

      def inject_svgr_esbuild(file)
        prepend_to_file file, "import svgr from 'esbuild-plugin-svgr'\n"
        gsub_file file, "importGlobPlugin()", "importGlobPlugin(), svgr()"
      end

      def inject_svgr_bun
        # bun uses esbuild-plugin-svgr since its plugin API is compatible
        prepend_to_file "bun.config.js", "import svgr from 'esbuild-plugin-svgr'\n"
        gsub_file "bun.config.js", "globImportPlugin()", "globImportPlugin(), svgr()"
      end

      def inject_svgr_webpack(file)
        inject_into_file file, after: /rules: \[\n/ do
          <<-JS
      {
        test: /\\.svg$/,
        use: ["@svgr/webpack"]
      },
          JS
        end
      end

      def inject_svgr_rollup(file)
        inject_into_file file, "import svgr from \"@svgr/rollup\"\n", before: /^export default/
        inject_into_file file, after: /plugins: \[\n/ do
          "    svgr(),\n"
        end
      end

      def app_js_path
        "app/javascript/"
      end
    end
  end
end
