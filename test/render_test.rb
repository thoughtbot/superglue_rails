require "test_helper"

class ReprodTest < ActionController::TestCase
  tests Admin::PostsController

  test "templates with prefixes render" do
    get :show

    assert_response 200
    rendered = <<~HTML
      <html>
        <body>
          <script type="text/javascript">
        window.SUPERGLUE_INITIAL_PAGE_STATE={"data":{"author":"john smith"}};
      </script>

      <div id="app"></div>  </body>
      </html>
    HTML
    assert_equal rendered, @response.body
    assert_equal "text/html", @response.media_type
  end
end

class RenderTest < ActionController::TestCase
  tests JsxController

  test "simple render with 3 templates (jsx, html, props)" do
    get :simple

    assert_response 200
    rendered = <<~HTML
      <html>
        <body>
          <script>{"data":{"author":"john smith"}}</script>
        </body>
      </html>
    HTML

    assert_equal rendered, @response.body
    assert_equal "text/html", @response.media_type
  end

  test "simple explicit render with 3 templates (jsx, html, props)" do
    get :simple

    assert_response 200
    rendered = <<~HTML
      <html>
        <body>
          <script>{"data":{"author":"john smith"}}</script>
        </body>
      </html>
    HTML

    assert_equal rendered, @response.body
    assert_equal "text/html", @response.media_type
  end

  test "render with 2 templates (jsx, props)" do
    get :valid_pair

    assert_response 200
    rendered = <<~HTML
      <html>
        <body>
          <script type="text/javascript">
        window.SUPERGLUE_INITIAL_PAGE_STATE={"data":{"author":"john smith"}};
      </script>

      <div id="app"></div>  </body>
      </html>
    HTML

    assert_equal rendered, @response.body
    assert_equal "text/html", @response.media_type
  end

  test "render with 2 templates (jsx, props) with no defaults enabled" do
    exception = assert_raise(ActionView::MissingTemplate) {
      get :valid_pair_no_defaults
    }

    assert_match("Missing template jsx/valid_pair", exception.message)
  end

  test "render with a valid single template (jsx)" do
    get :valid_single

    assert_response 200
    rendered = <<~HTML
      <html>
        <body>
          <script type="text/javascript">
        window.SUPERGLUE_INITIAL_PAGE_STATE={"data":{}};
      </script>

      <div id="app"></div>  </body>
      </html>
    HTML
    assert_equal rendered, @response.body
    assert_equal "text/html", @response.media_type
  end

  test "render with uncommon set of templates (html, jsx)" do
    get :uncommon_pair

    assert_response 200
    rendered = <<~HTML
      <html>
        <body>
          <script> OVERRIDE {"data":{}}</script>
        </body>
      </html>
    HTML

    assert_equal rendered, @response.body
    assert_equal "text/html", @response.media_type
  end

  test "render with html only" do
    exception = assert_raise(ActionView::MissingTemplate) {
      get :bad_single
    }

    assert_match("Missing template jsx/bad_single", exception.message)
  end

  test "render with bad pair of templates (html, json)" do
    exception = assert_raise(ActionView::MissingTemplate) {
      get :bad_pair
    }

    assert_match("Missing template jsx/bad_pair", exception.message)
  end

  test "rendering props only" do
    get :simple, format: :json

    assert_response 200
    rendered = <<~HTML
      {"data":{"author":"john smith"}}
    HTML

    assert_equal rendered, @response.body
    assert_equal "application/json", @response.media_type
  end

  test "non existant template" do
    exception = assert_raise(ActionView::MissingTemplate) {
      get :render_does_not_exist
    }
    assert_match("Missing template jsx/does_not_exist", exception.message)
  end

  test "non existant superglue template" do
    exception = assert_raise(ActionView::MissingTemplate) {
      get :simple_render_with_no_superglue_template
    }
    assert_match("Missing template /superglue-template-does-not-exist", exception.message)
  end

  test "unsupported render file:" do
    assert_raise(Superglue::Rendering::UnsupportedOption) {
      get :unsupported_option_file
    }
  end

  test "unsupported render partial:" do
    assert_raise(Superglue::Rendering::UnsupportedOption) {
      get :unsupported_option_partial
    }
  end

  test "unsupported render body:" do
    assert_raise(Superglue::Rendering::UnsupportedOption) {
      get :unsupported_option_body
    }
  end

  test "unsupported render plain:" do
    assert_raise(Superglue::Rendering::UnsupportedOption) {
      get :unsupported_option_plain
    }
  end

  test "unsupported render html:" do
    assert_raise(Superglue::Rendering::UnsupportedOption) {
      get :unsupported_option_html
    }
  end

  test "unsupported render inline:" do
    assert_raise(Superglue::Rendering::UnsupportedOption) {
      get :unsupported_option_inline
    }
  end
end
