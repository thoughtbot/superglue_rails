require "test_helper"
require "capybara/cuprite"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :cuprite, using: :chrome, screen_size: [1400, 1400], options: {js_errors: true}

  private

  def setup_superglue_dependency
    package_path = Rails.root.join("package.json")
    return unless File.exist?(package_path)

    package = JSON.parse(File.read(package_path))
    superglue_path = ENV["SUPERGLUEJS_PATH"] || "^1.0.0"

    if package.dig("dependencies", "@thoughtbot/superglue") != superglue_path
      package["dependencies"] ||= {}
      package["dependencies"]["@thoughtbot/superglue"] = superglue_path
      File.write(package_path, JSON.pretty_generate(package))

      # Run npm install to update dependencies
      system("cd #{Rails.root} && npm install && npm run build")
    end
  end
end

Capybara.configure do |config|
  config.server = :puma, {Silent: true}
end
