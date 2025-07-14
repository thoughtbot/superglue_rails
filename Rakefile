require "rake/testtask"
require "standard/rake"

task :build_dummy_js do
  package_path = File.join(__FILE__, "test/dummy/package.json")
  puts package_path
  superglue_version = ENV["SUPERGLUEJS_PATH"] || "^2.0.0-alpha.1"

  if File.exist?(package_path)
    package = JSON.parse(File.read(package_path))
    if package.dig("dependencies", "@thoughtbot/superglue") != superglue_version
      package["dependencies"] ||= {}
      package["dependencies"]["@thoughtbot/superglue"] = superglue_version
      File.write(package_path, JSON.pretty_generate(package))
    end
  end

  puts "Installing and building JS dependencies..."
  system("cd test/dummy && npm install && npm run build") or abort("npm install/build failed")
end

Rake::TestTask.new(test: :build_dummy_js) do |t|
  t.libs << "test"
  t.pattern = "test/**/*_test.rb"
  t.warning = false
  t.verbose = true
end
