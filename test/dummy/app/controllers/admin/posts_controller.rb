module Admin
  class PostsController < ApplicationController
    append_view_path "test/views"

    layout "layouts/jsx_application"

    def show
      render "admin/posts/index"
    end
  end
end
