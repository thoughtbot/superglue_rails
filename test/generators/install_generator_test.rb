require "test_helper"
require "rails/generators/test_case"
require "generators/superglue/install/install_generator"

class InstallGeneratorTest < Rails::Generators::TestCase
  tests Superglue::Generators::InstallGenerator
  destination File.expand_path("../../tmp/generators/install", __dir__)
  setup :prepare_destination

  test "defaults to TypeScript, typia and SVGR without TypeScript installed" do
    write_package_json

    choices = resolve_choices

    assert_equal "esbuild", choices[:bundler]
    assert choices[:use_typescript]
    assert_equal "typia", choices[:validator]
    assert choices[:use_svgr]
    assert_equal "typescript@^7", choices[:typescript_package]
  end

  test "defaults to deepkit on TypeScript 5" do
    write_package_json
    install_typescript("5.9.3")

    choices = resolve_choices

    assert_equal "deepkit", choices[:validator]
    assert_nil choices[:typescript_package]
  end

  test "defaults to deepkit on TypeScript 6" do
    write_package_json
    install_typescript("6.0.3")

    assert_equal "deepkit", resolve_choices[:validator]
  end

  test "defaults to typia on TypeScript 7" do
    write_package_json
    install_typescript("7.0.2")

    choices = resolve_choices

    assert_equal "typia", choices[:validator]
    assert_nil choices[:typescript_package]
  end

  test "reads the declared range when TypeScript is not installed" do
    write_package_json(typescript: "^5.4.2")

    choices = resolve_choices

    assert_equal "deepkit", choices[:validator]
    assert_nil choices[:typescript_package]
  end

  test "prefers the installed version over the declared range" do
    write_package_json(typescript: "^5.4.2")
    install_typescript("7.0.2")

    assert_equal "typia", resolve_choices[:validator]
  end

  test "treats a range without a version as undetected" do
    write_package_json(typescript: "latest")

    choices = resolve_choices

    assert_equal "typia", choices[:validator]
    assert_equal "typescript@^7", choices[:typescript_package]
  end

  test "installs TypeScript 6 for deepkit without TypeScript installed" do
    write_package_json

    choices = resolve_choices("--validator=deepkit")

    assert_equal "deepkit", choices[:validator]
    assert_equal "typescript@^6", choices[:typescript_package]
  end

  test "raises for typia on TypeScript 5" do
    write_package_json
    install_typescript("5.9.3")

    error = assert_raises(Thor::Error) { resolve_choices("--validator=typia") }

    assert_equal "typia requires TypeScript 7 or later, found TypeScript 5", error.message
  end

  test "raises for deepkit on TypeScript 7" do
    write_package_json
    install_typescript("7.0.2")

    error = assert_raises(Thor::Error) { resolve_choices("--validator=deepkit") }

    assert_equal "deepkit requires TypeScript 6 or earlier, found TypeScript 7", error.message
  end

  test "raises for an unknown validator" do
    write_package_json

    error = assert_raises(Thor::Error) { resolve_choices("--validator=zod") }

    assert_match "Unknown validator 'zod'", error.message
  end

  test "disables the validator with --no-validator" do
    write_package_json
    install_typescript("7.0.2")

    choices = resolve_choices("--no-validator")

    assert choices[:use_typescript]
    assert_equal "none", choices[:validator]
  end

  test "disables the validator with --skip-validator" do
    write_package_json

    assert_equal "none", resolve_choices("--skip-validator")[:validator]
  end

  test "still disables the validator with --validator=none" do
    write_package_json

    assert_equal "none", resolve_choices("--validator=none")[:validator]
  end

  test "allows --no-validator for JavaScript" do
    write_package_json

    choices = resolve_choices("--no-typescript", "--no-validator")

    refute choices[:use_typescript]
    assert_equal "none", choices[:validator]
  end

  test "uses no validator for JavaScript" do
    write_package_json

    choices = resolve_choices("--no-typescript")

    refute choices[:use_typescript]
    assert_equal "none", choices[:validator]
  end

  test "raises for a validator without TypeScript" do
    write_package_json

    error = assert_raises(Thor::Error) { resolve_choices("--no-typescript", "--validator=typia") }

    assert_match "requires TypeScript", error.message
  end

  test "disables SVGR with --no-svgr" do
    write_package_json

    refute resolve_choices("--no-svgr")[:use_svgr]
  end

  test "uses the requested bundler" do
    write_package_json

    assert_equal "webpack", resolve_choices("--bundler=webpack")[:bundler]
  end

  test "raises when no bundler is detected" do
    error = assert_raises(Thor::Error) do
      capture(:stdout) { resolve_choices }
    end

    assert_match "No bundler found", error.message
  end

  test "pins validator packages to superglue's peer ranges" do
    write_package_json
    install_superglue("ttsc" => ">=0.30.0 <0.31.0", "typia" => "^15.0.0")

    shell_arguments = Shellwords.split(peer_packages("typia", "ttsc", "@ttsc/unplugin").join(" "))

    assert_equal ["typia@^15.0.0", "ttsc@>=0.30.0 <0.31.0", "@ttsc/unplugin"], shell_arguments
  end

  test "installs validator packages unpinned without superglue installed" do
    write_package_json

    assert_equal ["typia", "ttsc"], peer_packages("typia", "ttsc")
  end

  private

  def peer_packages(*package_names)
    Dir.chdir(destination_root) do
      generator.send(:superglue_peer_packages, *package_names)
    end
  end

  def install_superglue(peer_dependencies)
    superglue_dir = File.join(destination_root, "node_modules", "@thoughtbot", "superglue")
    FileUtils.mkdir_p(superglue_dir)
    File.write(
      File.join(superglue_dir, "package.json"),
      JSON.generate({"name" => "@thoughtbot/superglue", "peerDependencies" => peer_dependencies})
    )
  end

  def resolve_choices(*flags)
    install_generator = generator([], flags)

    Dir.chdir(destination_root) do
      install_generator.send(:resolve_choices)

      {
        bundler: install_generator.instance_variable_get(:@bundler),
        use_typescript: install_generator.instance_variable_get(:@use_typescript),
        validator: install_generator.instance_variable_get(:@validator),
        use_svgr: install_generator.instance_variable_get(:@use_svgr),
        typescript_package: install_generator.send(:typescript_package)
      }
    end
  end

  # An esbuild app from jsbundling-rails, optionally declaring a typescript range.
  def write_package_json(typescript: nil)
    dev_dependencies = {"esbuild" => "^0.25.0"}
    dev_dependencies["typescript"] = typescript if typescript

    File.write(
      File.join(destination_root, "package.json"),
      JSON.generate({"name" => "app", "devDependencies" => dev_dependencies})
    )
  end

  def install_typescript(version)
    typescript_dir = File.join(destination_root, "node_modules", "typescript")
    FileUtils.mkdir_p(typescript_dir)
    File.write(File.join(typescript_dir, "package.json"), JSON.generate({"name" => "typescript", "version" => version}))
  end
end
