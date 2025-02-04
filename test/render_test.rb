require "test_helper"

class RenderController < TestController
  require "action_view/testing/resolvers"

  before_action :use_jsx_rendering_defaults, except: [:valid_pair_no_defaults]

  append_view_path(Superglue::Resolver.new("test/views"))
  append_view_path "test/views"

  layout "application"

  def simple
  end

  def simple_explicit
    render :simple
  end

  def valid_pair
  end

  def valid_pair_no_defaults
    render :valid_pair
  end

  def valid_single
    render :valid_single
  end

  def uncommon_pair
  end

  def bad_single
  end
  
  def bad_pair
  end

  def render_does_not_exist
    render :does_not_exist
  end

  def simple_render_with_no_superglue_template
    self._superglue_template = "superglue-template-does-not-exist"
    render :valid_pair
  end
  
  def unsupported_option_file
    render file: "render/simple.html.erb"
  end
  
  def unsupported_option_inline
    render inline: "blah"
  end
  
  def unsupported_option_html
    render html: "<h1></h1>"
  end
  
  def unsupported_option_body
    render body: "<h1></h1>"
  end
  
  def unsupported_option_partial
    render partial: "some-partial"
  end
  
  def unsupported_option_plain
    render plain: "plain"
  end

  def form_authenticity_token
    "secret"
  end
end

module Admin
  class ScopedController < TestController
    require "action_view/testing/resolvers"

    before_action :use_jsx_rendering_defaults

    append_view_path(Superglue::Resolver.new("test/views"))
    append_view_path "test/views"

    layout "application"

    def show
      render "admin/posts/index"
    end
  end
end

class ReprodTest < ActionController::TestCase
  tests Admin::ScopedController

  test "templates with prefixes render" do
    get :show

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
end

class RenderTest < ActionController::TestCase
  tests RenderController

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
          <script>{"data":{"author":"john smith"}}</script>
        </body>
      </html>
    HTML

    assert_equal rendered, @response.body
    assert_equal "text/html", @response.media_type
  end

  test "render with 2 templates (jsx, props) with no defaults enabled" do
    exception = assert_raise(ActionView::MissingTemplate) {
      get :valid_pair_no_defaults
    }

    assert_match("Missing template render/valid_pair", exception.message)
  end

  test "render with a valid single template (jsx)" do
    get :valid_single

    assert_response 200
    rendered = <<~HTML
      <html>
        <body>
          <script>{"data":{}}</script>
        </body>
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

    assert_match("Missing template render/bad_single", exception.message)
  end

  test "render with bad pair of templates (html, json)" do
    exception = assert_raise(ActionView::MissingTemplate) {
      get :bad_pair
    }

    assert_match("Missing template render/bad_pair", exception.message)
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
    assert_match("Missing template render/does_not_exist", exception.message)
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
