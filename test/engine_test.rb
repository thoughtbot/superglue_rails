require "test_helper"

class EngineTest < ActiveSupport::TestCase
  test "auto includes itself in action controller base" do
    assert ActionController::Base.included_modules.any? { |m| m.name && m.name.include?("Superglue") }
  end
end
