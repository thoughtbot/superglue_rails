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

      <div id="app"></div>
        </body>
      </html>
    HTML
    assert_equal rendered, @response.body
    assert_equal "text/html", @response.media_type
  end
end

class RenderTest < ActionController::TestCase
  tests JsxController

  test "simple render with 3 templates (html.jsx, html.erb, props)" do
    get :simple

    assert_response 200
    assert_equal "text/html", @response.media_type
  end

  test "simple explicit render with 3 templates (html.jsx, html.erb, props)" do
    get :simple_explicit

    assert_response 200
    assert_equal "text/html", @response.media_type
  end

  test "render with 2 templates (html.jsx, props)" do
    get :valid_pair

    assert_response 200
    rendered = <<~HTML
      <html>
        <body>
          <script type="text/javascript">
        window.SUPERGLUE_INITIAL_PAGE_STATE={"data":{"author":"john smith"}};
      </script>

      <div id="app"></div>
        </body>
      </html>
    HTML

    assert_equal rendered, @response.body
    assert_equal "text/html", @response.media_type
  end

  test "render with a valid single template (html.jsx)" do
    get :valid_single

    assert_response 200
    rendered = <<~HTML
      <html>
        <body>
          <script type="text/javascript">
        window.SUPERGLUE_INITIAL_PAGE_STATE={"data":{}};
      </script>

      <div id="app"></div>
        </body>
      </html>
    HTML
    assert_equal rendered, @response.body
    assert_equal "text/html", @response.media_type
  end

  test "render with uncommon set of templates (html.erb overrides html.jsx)" do
    get :uncommon_pair

    assert_response 200
    assert_includes @response.body, "OVERRIDE"
    assert_equal "text/html", @response.media_type
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

  test "rendering props with a non existant template still renders the layout" do
    get :no_json_template, format: :json

    assert_response 200
    rendered = <<~HTML
      {"data":{}}
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
end

class PropsOnlyController < ApplicationController
  append_view_path "test/views"

  layout "layouts/jsx_application"

  def simple
  end
end

class PropsRenderTest < ActionController::TestCase
  tests PropsOnlyController

  test "render with active template virtual path" do
    get :simple

    assert_response 200
    assert_includes @response.body, 'virtualPath":"props_only/simple'
  end
end
