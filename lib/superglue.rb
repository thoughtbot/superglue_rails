require "superglue/helpers"
require "superglue/rendering"
require "superglue/resolver"
require "props_template"
require "form_props"

module Superglue
  module Controller
    include Helpers

    def self.included(base)
      base.include ::Superglue::Rendering
      if base.respond_to?(:helper_method)
        base.helper_method :param_to_dig_path
        base.helper_method :render_props
      end
    end
  end

  class Engine < ::Rails::Engine
    config.superglue = ActiveSupport::OrderedOptions.new
    config.superglue.auto_include = true

    initializer :superglue do |app|
      ActiveSupport.on_load(:action_controller) do
        next if self != ActionController::Base

        if app.config.superglue.auto_include
          include Controller

          prepend_view_path(
            Superglue::Resolver.new(Rails.root.join("app/views"))
          )
        end
      end
    end
  end
end
