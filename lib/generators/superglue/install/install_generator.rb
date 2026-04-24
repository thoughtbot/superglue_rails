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

      class_option :deepkit,
        type: :boolean,
        required: false,
        desc: "Enable Deepkit runtime type validation (experimental). Skips interactive prompt."

      def create_files
        remove_file "#{app_js_path}/application.js"

        @use_typescript = options["typescript"]
        @bundler = ask_bundler
        @use_deepkit = @use_typescript && ask_deepkit

        copy_erb_files

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

        say "Copying application.json.props"
        copy_file "#{__dir__}/templates/application.json.props", "app/views/layouts/application.json.props"

        say "Copying stream.json.props"
        copy_file "#{__dir__}/templates/stream.json.props", "app/views/layouts/stream.json.props"

        say "Adding required member methods to ApplicationRecord"
        add_member_methods

        say "Enabling jsx rendering defaults"
        insert_jsx_rendering_defaults

        install_packages

        say "Superglue is Installed! 🎉", :green
      end

      private

      BUNDLERS = %w[esbuild bun rollup webpack].freeze

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

      def ask_deepkit
        unless options["deepkit"].nil?
          say "Deepkit runtime type validation: #{options["deepkit"] ? "enabled" : "disabled"}", :green
          return options["deepkit"]
        end

        say ""
        say "Superglue includes an experimental Deepkit integration for runtime type"
        say "validation during development. This is optional and can be added later."
        yes?("Would you like to enable Deepkit runtime type validation? (experimental) [y/N]")
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

      def copy_bundler_config
        case @bundler
        when "esbuild"
          if @use_typescript
            template_name = @use_deepkit ? "ts/build.deepkit.mjs" : "ts/build.mjs"
            say "Adding build.mjs for TypeScript compilation"
            copy_file "#{__dir__}/templates/#{template_name}", "build.mjs"
          else
            say "Adding build.mjs"
            copy_file "#{__dir__}/templates/js/build.mjs", "build.mjs"
          end
        when "bun"
          config_template = if @use_typescript
            @use_deepkit ? "bun/bun.config.deepkit.js" : "bun/bun.config.ts.js"
          else
            "bun/bun.config.js"
          end
          say "Overwriting bun.config.js with Superglue configuration"
          copy_file "#{__dir__}/templates/#{config_template}", "bun.config.js"
        when "webpack"
          config_template = if @use_typescript
            @use_deepkit ? "webpack/webpack.config.deepkit.js" : "webpack/webpack.config.ts.js"
          else
            "webpack/webpack.config.js"
          end
          say "Overwriting webpack.config.js with Superglue configuration"
          copy_file "#{__dir__}/templates/#{config_template}", "webpack.config.js"
        when "rollup"
          config_template = if @use_typescript
            @use_deepkit ? "rollup/rollup.config.deepkit.js" : "rollup/rollup.config.ts.js"
          else
            "rollup/rollup.config.js"
          end
          say "Overwriting rollup.config.js with Superglue configuration"
          copy_file "#{__dir__}/templates/#{config_template}", "rollup.config.js"
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
        superglue_pkg = ENV.fetch("TEST_SUPERGLUEJS_PKG", "@thoughtbot/superglue@2.0.0-beta.2")
        run "yarn add react react-dom #{superglue_pkg}"

        if @use_typescript
          run "yarn add -D @types/react-dom @types/react @types/node @thoughtbot/candy_wrapper@0.0.4 typescript"
        end

        if @use_deepkit
          say "Installing Deepkit for runtime type validation"
          run "yarn add -D @deepkit/type @deepkit/core @deepkit/type-compiler"
        end

        case @bundler
        when "bun"
          say "Installing bun glob plugin"
          run "yarn add -D bun-plugin-glob-import"
        when "webpack"
          say "Installing esbuild-loader for JSX support"
          run "yarn add -D esbuild-loader"
        when "rollup"
          say "Installing rollup plugins for JSX and glob support"
          run "yarn add -D @rollup/plugin-babel @babel/core @babel/preset-react @rollup/plugin-commonjs @rollup/plugin-alias rollup-plugin-import-meta-glob"
          if @use_typescript
            run "yarn add -D @babel/preset-typescript"
          end
        end
      end

      def insert_jsx_rendering_defaults
        inject_into_file "app/controllers/application_controller.rb", after: "class ApplicationController < ActionController::Base\n" do
          <<-RUBY
  # Enables Superglue rendering defaults for sensible view directories.
  #
  # without `use_jsx_rendering_defaults`:
  #
  # ```
  # app/views/posts/
  #  - index.jsx
  #  - index.json.props
  #  - index.html.erb
  # ```
  #
  # with `use_jsx_rendering_defaults`:
  #
  # ```
  # app/views/posts/
  #   - index.jsx
  #   - index.json.props
  # ```
  #
  # before_action :use_jsx_rendering_defaults
  #
  #
  # The html template used when `use_jsx_rendering_defaults` is enabled.
  # Defaults to "application/superglue".
  #
  # superglue_template "application/superglue"

          RUBY
        end
      end

      def copy_erb_files
        say "Copying superglue.html.erb file to app/views/application/"
        copy_file "#{__dir__}/templates/erb/superglue.html.erb", "app/views/application/superglue.html.erb"
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

        if @use_deepkit
          say "Enabling Deepkit reflection in tsconfig.json"
          inject_into_file "tsconfig.json", before: /\n\}$/ do
            ",\n  \"reflection\": true"
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

      def app_js_path
        "app/javascript/"
      end
    end
  end
end
