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
        _ensure_react_page!(options[:template], options[:prefixes]) if request.format.html?

        target_template_exists = template_exists?(options[:template], options[:prefixes], false)

        if request.format.html? && !target_template_exists
          # this uses the default superglue html template, which is super basic so
          # we don't' need to create a separate one for each view
          super(options.merge(
            template: _superglue_template,
            prefixes: []
          ))
        elsif request.format.json? && !target_template_exists
          # This fixes an issue with rendering json direclty but teh template doesn't exist
          # we still want ot see the layout rendered
          super(options.merge(
            inline: "",
            layout: _layout_for_option(true)
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
      @_use_jsx_rendering_defaults && (request.format.html? || request.format.json?)
    end

    def _props_defaults
      @_use_jsx_rendering_defaults && request.format.json?
    end

    def _ensure_react_page!(template, prefixes)
      found_template = lookup_context.find(template, prefixes, false, [], formats: [], handlers: [], variants: [], locale: [])
      ## This variable was created for props_template to pick up
      @_active_template_virtual_path = found_template.virtual_path
      found_template
    rescue ActionView::MissingTemplate => e
      raise ActionView::MissingTemplate.new(e.paths, e.path, e.prefixes, e.partial, "extension JSX or TSX")
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
