require "test_helper"

class HelpersTest < ActiveSupport::TestCase
  include Superglue::Helpers

  test "clean_props_at returns nil if qry is nil" do
    qry = nil

    assert_nil param_to_dig_path(qry)
  end

  test "clean_props_at returns a refined qry" do
    qry = "foo...bar/?)()-"

    assert_equal param_to_dig_path(qry), ["foo", "bar"]
  end

  test "raises error when depth exceeds limit" do
    deep_path = (1..51).map(&:to_s).join(".")
    
    error = assert_raises(Superglue::Helpers::DigPathTooDeepError) do
      param_to_dig_path(deep_path)
    end
    
    assert_match(/Parameter dig path too deep: 51 levels/, error.message)
    assert_match(/maximum allowed: 50/, error.message)
  end
  
  test "allows paths at the depth limit" do
    exact_limit_path = (1..50).map(&:to_s).join(".")
    result = param_to_dig_path(exact_limit_path)
    
    assert_equal 50, result.length
    assert_equal (1..50).map(&:to_s), result
  end
  
  test "allows normal depth paths" do
    normal_path = "users.0.posts.2.title"
    result = param_to_dig_path(normal_path)
    
    assert_equal ["users", "0", "posts", "2", "title"], result
    assert_equal 5, result.length
  end
end
