require "rake/testtask"
require "standard/rake"
require "dotenv/load"

def build_superglue_tgz(superglue_dir)
  system("cd #{superglue_dir} && npm install && npm run build && npm pack") or abort("superglue build failed")

  tgz = Dir.glob("#{superglue_dir}/thoughtbot-superglue-*.tgz").max_by { |f| File.mtime(f) }
  abort("No .tgz found in #{superglue_dir}") unless tgz

  "file:#{tgz}"
end

task :build_dummy_js do
  package_path = File.join(__FILE__, "test/dummy/package.json")
  puts package_path

  superglue_version = if ENV["SUPERGLUE_DIR"]
    build_superglue_tgz(ENV["SUPERGLUE_DIR"])
  else
    "^2.0.0-beta.2"
  end

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
