require "test_helper"

# Copied into the generated app as test/integration/content_validation_test.rb
# by the acceptance test, and run there with `rails test`.
#
# Renders the scaffold's show page server side for a valid post and for one
# whose body is nil, which breaks the page's `body: string` type.
# EXPECT_VALIDATION=1 means the app was installed with a runtime type
# validator, so the invalid post must raise ContentValidationError during the
# server render; otherwise both posts render.
class ContentValidationTest < ActionDispatch::IntegrationTest
  test "renders a valid post" do
    post = Post.create!(body: "hello")

    get post_path(post)

    assert_response :success
  end

  test "handles a post that breaks its type" do
    post = Post.create!(body: nil)
    expect_validation = ENV["EXPECT_VALIDATION"] == "1"

    if expect_validation
      error = assert_raises(ActionView::Template::Error) { get post_path(post) }
      assert_match(/\AContentValidationError: \[Superglue\] Content validation failed/, error.message)
    else
      get post_path(post)
      assert_response :success
    end
  end
end
