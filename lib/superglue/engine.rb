module Superglue
  module Controller
    include Helpers

    def self.included(base)
      base.include ::Superglue::Rendering
      return unless base.respond_to?(:helper_method)

      base.helper_method :param_to_dig_path
      base.helper_method :render_props
    end
  end

  class Engine < ::Rails::Engine
    config.superglue = ActiveSupport::OrderedOptions.new
    config.superglue.auto_include = true

    initializer :superglue do |app|
      ActiveSupport.on_load(:action_controller) do
        next if self != ActionController::Base

        include Controller
        include Superglue::RequestIdTracking

        prepend_view_path(
          Superglue::Resolver.new(Rails.root.join("app/views"))
        )
      end
    end

    initializer "superglue.signed_stream_verifier_key" do
      config.after_initialize do
        Superglue.signed_stream_verifier_key = config.superglue.signed_stream_verifier_key ||
          Rails.application.key_generator.generate_key("superglue/signed_stream_verifier_key")
      end
    end
  end
end
