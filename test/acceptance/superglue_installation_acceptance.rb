require "minitest/autorun"
require "capybara"
require "capybara/minitest"
require "selenium-webdriver"
require "git"
require "dotenv/load"

ROOT_DIR = File.expand_path("../../../", __FILE__)
TMP_DIR = File.join(ROOT_DIR, "tmp")
SUPERGLUE_RAILS_PATH = ROOT_DIR
SUPERGLUE_SUPERGLUE_PATH = File.join(ROOT_DIR, "superglue/superglue")
VERSION = File.read(File.expand_path("../../VERSION", __dir__)).strip

SERVER_PORT = "3000"

USE_TYPESCRIPT = ENV["USE_TYPESCRIPT"] == "1"

Minitest.load_plugins

class << Minitest
  remove_method :plugin_rails_init if method_defined?(:plugin_rails_init)
end

class SuperglueInstallationTest < Minitest::Test
  include Capybara::DSL
  include Capybara::Minitest::Assertions

  def teardown
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end

  def setup
    ENV["BUNDLE_GEMFILE"] = nil

    Capybara.javascript_driver = :selenium_chrome_headless
    Capybara.current_driver = Capybara.javascript_driver
    Capybara.app_host = "http://localhost:#{SERVER_PORT}"
    Capybara.server_host = "localhost"
    Capybara.server_port = SERVER_PORT
  end

  def successfully(command, silent = false)
    silencer = if silent
      "1>/dev/null"
    else
      ""
    end

    return_value = system("#{command} #{silencer}")

    assert return_value
  end

  def update_package_json
    js_version = JSON.parse(
      File.read(File.expand_path("package.json", SUPERGLUE_SUPERGLUE_PATH)).strip
    )["version"]

    content = File.read("package.json").gsub(
      /"@thoughtbot\/superglue.*$/,
      "\"@thoughtbot/superglue\":\"file:#{SUPERGLUE_SUPERGLUE_PATH}/thoughtbot-superglue-#{js_version}.tgz\","
    )

    File.open("package.json", "w") { |file| file.puts content }
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

  def install_superglue
    tgz = build_superglue_package

    successfully "echo \"gem 'superglue', path: '#{SUPERGLUE_RAILS_PATH}'\" >> Gemfile"
    successfully "bundle install"

    FileUtils.rm_f("app/javascript/application.js")

    successfully "TEST_SUPERGLUEJS_PKG='file:#{tgz}' bundle exec rails generate superglue:install --bundler=esbuild --no-deepkit #{"--typescript" if USE_TYPESCRIPT}"
    successfully "rm -rf node_modules/@thoughtbot/superglue"
    successfully "yarn cache clean"
    successfully "yarn add --force file:#{tgz}"
  end

  def add_esbuild_cmd
    build_script = "node build.mjs"
    successfully %(npm pkg set scripts.build="#{build_script}")
  end

  def generate_test_app_7(app_name)
    successfully "rails new #{app_name} \
       --javascript=esbuild \
       --skip-git \
       --skip-hotwire \
       --skip-spring \
       --no-rc \
       --skip_bootsnap"
  end

  def generate_scaffold
    successfully "bundle exec rails generate superglue:scaffold post body:string --force #{"--typescript" if USE_TYPESCRIPT}"
  end

  def reset_db
    successfully "RAILS_ENV=development bundle exec rake db:drop"
    successfully "RAILS_ENV=development bundle exec rake db:create"
    successfully "RAILS_ENV=development bundle exec rake db:migrate"
  end

  def compile_assets
    successfully "RAILS_ENV=development bundle exec rails assets:precompile"
  end

  def server_up
    pid = spawn "RAILS_ENV=development RAILS_SERVE_STATIC_FILES=t SECRET_KEY_BASE=FOOBAR bundle exec rails server -p #{SERVER_PORT}"
    sleep 5

    pid
  end

  def test_installation
    pid = nil
    Dir.mkdir(TMP_DIR) unless Dir.exist?(TMP_DIR)
    Dir.chdir(TMP_DIR) do
      FileUtils.rm_rf("testapp")
      generate_test_app_7 "testapp"
      Dir.chdir("testapp") do
        successfully "bundle install"
        successfully "yarn add react react-dom @babel/preset-react"

        FileUtils.rm_f("public/index.html")
        install_superglue
        generate_scaffold
        reset_db
        add_esbuild_cmd
        compile_assets
        pid = server_up
      end
    end

    visit("/posts")
    assert page.has_content?("Body")
    assert page.has_content?("New Post")
    find("a", text: "New Post").click
    assert page.has_content?("Back")

    fill_in "post_body", with: "foobar"
    click_button "Create Post"
    successfully "ls #{TMP_DIR}/testapp/log/"
    sleep 30
    assert page.has_content?("Post was successfully created.")
    find("a", text: "Edit").click

    fill_in "post_body", with: "foobar"
    click_button "Update Post"
    assert page.has_content?("Post was successfully updated.")

    find("a", text: "Back").click
    assert page.has_content?("foobar")

    click_button "Delete"
    assert page.has_content?("Post was successfully destroyed.")
  ensure
    if pid
      Process.kill "TERM", pid
      Process.wait pid
    end
  end
end
