require "json"
require "rails/generators/named_base"
require "rails/generators/resource_helpers"

module Superglue
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("../templates", __FILE__)

      class_option :typescript,
        type: :boolean,
        required: false,
        default: false,
        desc: "Use typescript"

      class_option :bundler,
        type: :string,
        required: false,
        desc: "JavaScript bundler to use (esbuild, bun, rollup, webpack). Skips interactive prompt."

      class_option :validator,
        type: :string,
        required: false,
        desc: "Runtime type validator to use (deepkit, typia, none). Skips interactive prompt."

      class_option :svgr,
        type: :boolean,
        required: false,
        desc: "Enable SVGR to import SVGs as React components. Skips interactive prompt."

      def create_files
        remove_file "#{app_js_path}/application.js"

        @use_typescript = options["typescript"]
        @bundler = ask_bundler
        @validator = @use_typescript ? ask_validator : "none"
        @use_svgr = ask_svgr

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

      def ask_bundler
        if options["bundler"]
          bundler = options["bundler"]
          unless BUNDLERS.include?(bundler)
            raise Thor::Error, "Unknown bundler '#{bundler}'. Must be one of: #{BUNDLERS.join(", ")}"
          end
          say "Using bundler: #{bundler}", :green
          return bundler
        end

        detected = detect_bundler

        if detected
          say "Detected #{detected} in your project.", :green
        else
          say "No JavaScript bundler detected.", :red
          say "Install one first via jsbundling-rails:"
          say "  rails javascript:install:[esbuild|bun|rollup|webpack]"
          say "See: https://github.com/rails/jsbundling-rails"
          raise Thor::Error, "No bundler found. Install one via jsbundling-rails and re-run this generator."
        end

        ask("Which bundler are you using?", limited_to: BUNDLERS, default: detected)
      end

      def ask_validator
        if options["validator"]
          validator = options["validator"]
          unless VALIDATORS.include?(validator)
            raise Thor::Error, "Unknown validator '#{validator}'. Must be one of: #{VALIDATORS.join(", ")}"
          end
          say "Runtime type validator: #{validator}", :green
          return validator
        end

        say ""
        say "Superglue can add runtime type validation during development."
        say "  deepkit - works with TypeScript 5 and below (uses bundler plugin)"
        say "  typia   - works with TypeScript 6 and above (uses ttsc)"
        say "  none    - skip runtime type validation"
        ask("Which runtime type validator would you like to use?", limited_to: VALIDATORS, default: "none")
      end

      def ask_svgr
        unless options["svgr"].nil?
          say "SVGR: #{options["svgr"] ? "enabled" : "disabled"}", :green
          return options["svgr"]
        end

        say ""
        say "SVGR lets you import SVGs as React components."
        say "e.g., import Logo from '@images/logo.svg'"
        yes?("Would you like to enable SVGR? [y/N]")
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
        run "yarn add react react-dom @thoughtbot/superglue@^2.0.0-beta.11"

        if @use_typescript
          run "yarn add -D @types/react-dom @types/react @types/node @thoughtbot/candy_wrapper@0.0.4 typescript"
        end

        if @validator == "deepkit"
          say "Installing Deepkit for runtime type validation"
          run "yarn add -D @deepkit/type @deepkit/core @deepkit/type-compiler"
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
          say "Installing rollup plugins for JSX and glob support"
          run "yarn add -D @rollup/plugin-babel @babel/core @babel/preset-react @rollup/plugin-commonjs @rollup/plugin-alias @rollup/plugin-replace rollup-plugin-import-meta-glob"
          if @use_typescript
            run "yarn add -D @babel/preset-typescript"
          end
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
          if @use_typescript
            gsub_file "rollup.config.ssr.js",
              'presets: [["@babel/preset-react", { runtime: "automatic" }]],',
              'presets: [["@babel/preset-react", { runtime: "automatic" }], "@babel/preset-typescript"],'
          end
          run %(npm pkg set scripts.build:ssr="rollup -c rollup.config.ssr.js")
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
