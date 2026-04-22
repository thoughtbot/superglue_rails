require "minitest/autorun"
require "json"
require "fileutils"

ROOT_DIR = File.expand_path("../../../", __FILE__)
TMP_DIR = File.join(ROOT_DIR, "tmp")
SUPERGLUE_RAILS_PATH = ROOT_DIR
SUPERGLUE_SUPERGLUE_PATH = File.join(ROOT_DIR, "superglue/superglue")
VERSION = File.read(File.expand_path("../../VERSION", __dir__)).strip

JS_VERSION = JSON.parse(
  File.read(File.expand_path("package.json", SUPERGLUE_SUPERGLUE_PATH)).strip
)["version"]

SUPERGLUE_TGZ = File.join(SUPERGLUE_SUPERGLUE_PATH, "thoughtbot-superglue-#{JS_VERSION}.tgz")

USE_TYPESCRIPT = ENV["USE_TYPESCRIPT"] == "1"
BUNDLER = ENV.fetch("BUNDLER", "esbuild")

Minitest.load_plugins

class << Minitest
  remove_method :plugin_rails_init if method_defined?(:plugin_rails_init)
end

class BundlerVerificationTest < Minitest::Test
  def setup
    ENV["BUNDLE_GEMFILE"] = nil
  end

  def successfully(command)
    puts "  -> #{command}"
    return_value = system(command)
    assert return_value, "Command failed: #{command}"
  end

  def generate_test_app(app_name, bundler)
    successfully "rails new #{app_name} \
      --javascript=#{bundler} \
      --skip-git \
      --skip-hotwire \
      --skip-spring \
      --no-rc \
      --skip_bootsnap"
  end

  def build_superglue_package
    superglue_dir = ENV["SUPERGLUE_DIR"] || SUPERGLUE_SUPERGLUE_PATH

    if !ENV["SUPERGLUE_DIR"] && !File.exist?(File.join(superglue_dir, "package.json"))
      Dir.chdir(ROOT_DIR) do
        successfully "git submodule update --init"
      end
    end

    Dir.chdir(superglue_dir) do
      successfully "npm install"
      successfully "npm run build"
      successfully "npm pack"
    end

    tgz = Dir.glob("#{superglue_dir}/thoughtbot-superglue-*.tgz").max_by { |f| File.mtime(f) }
    raise "No .tgz found in #{superglue_dir}" unless tgz

    tgz
  end

  def install_superglue(bundler)
    tgz = build_superglue_package

    successfully "echo \"gem 'superglue', path: '#{SUPERGLUE_RAILS_PATH}'\" >> Gemfile"
    successfully "bundle install"

    FileUtils.rm_f("app/javascript/application.js")

    typescript_flag = USE_TYPESCRIPT ? "--typescript" : ""

    successfully "TEST_SUPERGLUEJS_PKG='file:#{tgz}' bundle exec rails generate superglue:install --bundler=#{bundler} #{typescript_flag}"
  end

  def update_superglue_package
    content = File.read("package.json").gsub(
      /"@thoughtbot\/superglue.*$/,
      "\"@thoughtbot/superglue\":\"file:#{SUPERGLUE_TGZ}\","
    )
    File.open("package.json", "w") { |file| file.puts content }
  end

  def add_build_cmd(bundler)
    # The installer now handles build script updates for esbuild and rollup.
    # No additional build command changes needed.
  end

  def generate_scaffold
    typescript_flag = USE_TYPESCRIPT ? "--typescript" : ""
    successfully "bundle exec rails generate superglue:scaffold post body:string --force #{typescript_flag}"
  end

  def run_build
    successfully "yarn build"
  end

  def verify_bundle
    bundle_path = "app/assets/builds/application.js"
    assert File.exist?(bundle_path), "Bundle not found at #{bundle_path}"

    bundle_content = File.read(bundle_path)
    bundle_size = File.size(bundle_path)

    puts "\n  Bundle size: #{(bundle_size / 1024.0).round(1)} KB"

    # Check for React runtime
    has_react = bundle_content.include?("createElement") || bundle_content.include?("jsx")
    assert has_react, "Bundle does not contain React runtime code"

    # Check for Superglue library
    has_superglue = bundle_content.include?("superglue") ||
      bundle_content.include?("Superglue") ||
      bundle_content.include?("SUPERGLUE") ||
      bundle_content.include?("graft") ||
      bundle_content.include?("savePage")
    assert has_superglue, "Bundle does not contain Superglue library code"

    # Check for scaffolded page components
    has_page_components = bundle_content.include?("posts") ||
      bundle_content.include?("Posts") ||
      bundle_content.include?("post")
    assert has_page_components, "Bundle does not contain scaffolded page components"

    # Check sourcemap exists
    sourcemap_path = "#{bundle_path}.map"
    has_sourcemap = File.exist?(sourcemap_path) || bundle_content.include?("sourceMappingURL")
    assert has_sourcemap, "No sourcemap found"

    puts "  ✓ React runtime present"
    puts "  ✓ Superglue library present"
    puts "  ✓ Scaffolded page components present"
    puts "  ✓ Sourcemap present"
  end

  def test_bundler_produces_valid_bundle
    bundler = BUNDLER
    app_name = "testapp_#{bundler}"
    ext = USE_TYPESCRIPT ? "tsx" : "jsx"

    puts "\n=== Testing #{bundler} bundler (TypeScript: #{USE_TYPESCRIPT}) ==="

    Dir.mkdir(TMP_DIR) unless Dir.exist?(TMP_DIR)
    Dir.chdir(TMP_DIR) do
      FileUtils.rm_rf(app_name)
      generate_test_app(app_name, bundler)

      Dir.chdir(app_name) do
        successfully "bundle install"

        install_superglue(bundler)
        generate_scaffold
        add_build_cmd(bundler)

        successfully "RAILS_ENV=development bundle exec rake db:create db:migrate"

        # Verify the correct page_to_page_mapping was generated
        mapping_file = "app/javascript/page_to_page_mapping.#{USE_TYPESCRIPT ? "ts" : "js"}"
        assert File.exist?(mapping_file), "page_to_page_mapping not found at #{mapping_file}"

        mapping_content = File.read(mapping_file)
        case bundler
        when "esbuild"
          assert mapping_content.include?("pageIdentifierToPageComponent = {"),
            "esbuild mapping should use manual imports"
          puts "  ✓ Correct page_to_page_mapping for esbuild (manual imports)"
        when "bun"
          assert mapping_content.include?("asObject as pages"),
            "bun mapping should use bun-plugin-glob-import"
          puts "  ✓ Correct page_to_page_mapping for bun (glob-import)"
        when "webpack"
          assert mapping_content.include?("require.context"),
            "webpack mapping should use require.context"
          puts "  ✓ Correct page_to_page_mapping for webpack (require.context)"
        when "rollup"
          assert mapping_content.include?("import.meta.glob"),
            "rollup mapping should use import.meta.glob"
          puts "  ✓ Correct page_to_page_mapping for rollup (import.meta.glob)"
        end

        # Verify bundler config was created/overwritten
        case bundler
        when "esbuild"
          assert File.exist?("build.mjs"), "build.mjs should exist for esbuild"
          puts "  ✓ build.mjs present"
        when "bun"
          assert File.exist?("bun.config.js"), "bun.config.js should exist"
          config = File.read("bun.config.js")
          assert config.include?("globImportPlugin"), "bun.config.js should include glob plugin"
          puts "  ✓ bun.config.js with glob plugin present"
        when "webpack"
          assert File.exist?("webpack.config.js"), "webpack.config.js should exist"
          config = File.read("webpack.config.js")
          assert config.include?("esbuild-loader"), "webpack.config.js should use esbuild-loader"
          assert config.include?(".#{ext}"), "webpack.config.js should reference .#{ext}"
          puts "  ✓ webpack.config.js with esbuild-loader present"
        when "rollup"
          assert File.exist?("rollup.config.js"), "rollup.config.js should exist"
          config = File.read("rollup.config.js")
          assert config.include?("importMetaGlob"), "rollup.config.js should include glob plugin"
          assert config.include?("@rollup/plugin-babel"), "rollup.config.js should include babel"
          assert config.include?("@rollup/plugin-alias"), "rollup.config.js should include alias"
          puts "  ✓ rollup.config.js with babel, alias, and glob plugins present"
        end

        # Build the bundle
        puts "\n  Building bundle with #{bundler}..."
        run_build

        # Verify the bundle output
        verify_bundle

        puts "\n=== #{bundler} bundler verification PASSED ✓ ===\n"
      end
    end
  end
end
