module Admin
  class ScopedController < ApplicationController
    append_view_path "test/views"

    layout "application"

    def show
      render "admin/posts/index"
    end
  end
end
