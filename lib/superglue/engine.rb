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
    isolate_namespace Superglue
    config.eager_load_namespaces << Superglue
    config.superglue = ActiveSupport::OrderedOptions.new
    config.superglue.auto_include = true
    config.autoload_once_paths = %W[
      #{root}/app/channels
      #{root}/app/controllers
      #{root}/app/controllers/concerns
      #{root}/app/helpers
      #{root}/app/models
      #{root}/app/models/concerns
      #{root}/app/jobs
    ]

    # If the parent application does not use Action Cable, app/channels cannot
    # be eager loaded, because it references the ActionCable constant.
    # This approach was ported from the amazing folks at turbo-rails
    # You can find its MIT License here: https://github.com/hotwired/turbo-rails/blob/main/MIT-LICENSE
    initializer :"superglue.no_action_cable", before: :set_eager_load_paths do
      unless defined?(ActionCable)
        Rails.autoloaders.once.do_not_eager_load("#{root}/app/channels")
      end
    end

    initializer :superglue do |app|
      ActiveSupport.on_load(:action_controller) do
        next if self != ActionController::Base

        include Controller
      end
    end

    initializer "superglue.template_handlers" do
      handler = ->(template, source) {
        <<~RUBY
          controller.instance_variable_set(:@_active_template_virtual_path, "#{template.virtual_path}")
          if controller.instance_variable_get(:@_ssr_enabled) && controller.instance_variable_get(:@_ssr_context)
            render(partial: "humid", locals: { ssr_context: controller.instance_variable_get(:@_ssr_context) }).strip.html_safe
          else
            ""
          end
        RUBY
      }

      ActionView::Template.register_template_handler :tsx, handler
      ActionView::Template.register_template_handler :jsx, handler
    end

    initializer "superglue.helpers" do
      ActiveSupport.on_load(:action_controller) do
        helper Superglue::StreamsHelper
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
