class JsxController < ApplicationController
  before_action :use_jsx_rendering_defaults, except: [:valid_pair_no_defaults]

  append_view_path(Superglue::Resolver.new("test/views"))
  append_view_path "test/views"

  layout "layouts/jsx_application"

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
    render file: "jsx/simple.html.erb"
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
