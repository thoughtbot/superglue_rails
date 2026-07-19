class JsxController < ApplicationController
  append_view_path "test/views"

  layout "layouts/jsx_application"

  def simple
  end

  def simple_explicit
    render :simple
  end

  def valid_pair
  end

  def valid_single
    render :valid_single
  end

  def uncommon_pair
  end

  def no_json_template
  end

  def render_does_not_exist
    render :does_not_exist
  end

  def form_authenticity_token
    "secret"
  end
end
