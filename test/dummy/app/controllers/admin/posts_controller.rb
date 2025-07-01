module Admin
  class PostsController < ApplicationController
    before_action :use_jsx_rendering_defaults

    append_view_path(Superglue::Resolver.new("test/views"))
    append_view_path "test/views"

    layout "layouts/jsx_application"

    def show
      render "admin/posts/index"
    end
  end
end
