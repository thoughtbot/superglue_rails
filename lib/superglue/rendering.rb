require "active_support/concern"

module Superglue
  module Rendering
    class UnsupportedOption < StandardError; end

    extend ActiveSupport::Concern

    included do |base|
      base.class_attribute :_superglue_template, instance_accessor: true, default: "application/superglue"
    end

    class_methods do
      def superglue_template(template)
        self._superglue_template = template
      end
    end

    def _render_template(options = {})
      if @_capture_options_before_render
        @_capture_options_before_render = false

        if options.keys.intersect? [:file, :partial, :body, :plain, :html, :inline]
          raise UnsupportedOption.new("`template:` and `action:` are the only options supported with `use_jsx_rendering_defaults`")
        end

        @_render_options = options
        _ensure_react_page!(options[:template], options[:prefixes])

        html_template_exist = template_exists?(options[:template], options[:prefixes], false)
        if !html_template_exist
          super(options.merge(
            template: _superglue_template,
            prefixes: []
          ))
        else
          super
        end
      else
        super
      end
    end

    def render(...)
      if _jsx_defaults
        @_capture_options_before_render = true
      end

      super
    end

    def use_jsx_rendering_defaults
      @_use_jsx_rendering_defaults = true
    end

    def _jsx_defaults
      @_use_jsx_rendering_defaults && request.format.html?
    end

    def _ensure_react_page!(template, prefixes)
      lookup_context.find(template, prefixes, false, [], formats: [], handlers: [], variants: [], locale: [])
    end

    def default_render
      if _jsx_defaults
        render
      else
        super
      end
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
