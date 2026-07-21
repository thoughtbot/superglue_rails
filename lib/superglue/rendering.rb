require "active_support/concern"

module Superglue
  module Rendering
    extend ActiveSupport::Concern

    included do |base|
      base.class_attribute :_ssr_context_block, instance_accessor: true, default: nil
    end

    class_methods do
      def ssr_context(&block)
        self._ssr_context_block = block
      end
    end

    def default_render
      if request.format.json? && !template_exists?(action_name, _prefixes, false)
        render inline: "", layout: true
      else
        super
      end
    end

    def _render_template(options = {})
      @_render_options ||= options
      super
    end

    def render_props
      if @_render_options
        options = @_render_options

        if template_exists?(options[:template], options[:prefixes], formats: [:json])
          _render_template(options.merge({formats: [:json], layout: _layout_for_option(true)})).strip.html_safe
        else
          options.delete(:template)
          options.delete(:action)
          _render_template(options.merge({inline: "", formats: [:json], layout: _layout_for_option(true)})).strip.html_safe
        end
      else
        ""
      end
    end
  end
end
