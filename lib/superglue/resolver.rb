require 'action_view'

module Superglue
  class Resolver < ActionView::FileSystemResolver
    class JsxPathParser < ActionView::Resolver::PathParser
      REACT_FORMATS = [:tsx, :jsx]

      def build_path_regex
        formats = Regexp.union(REACT_FORMATS.map(&:to_s))

        %r{
          \A
          (?:(?<prefix>.*)/)?
          (?<action>.*?)
          (?:\.(?<format>#{formats}))??
          \z
        }x
      end

      def parse(path)
        @regex ||= build_path_regex
        match = @regex.match(path)
        path = ActionView::TemplatePath.build(match[:action], match[:prefix] || "", false)
        details = ActionView::TemplateDetails.new(
          nil,
          nil,
          match[:format]&.to_sym,
          nil
        )
        ParsedPath.new(path, details)
      end
    end

    def initialize(path)
      raise ArgumentError, "path already is a Resolver class" if path.is_a?(ActionView::Resolver)
      @unbound_templates = Concurrent::Map.new
      @path_parser = JsxPathParser.new
      @path = File.expand_path(path)
    end

    def clear_cache
      @unbound_templates.clear
      @path_parser = JsxPathParser.new
    end

    def source_for_template(template)
      "''"
    end

    def filter_and_sort_by_details(templates, requested_details)
      if requested_details.formats.empty?
        templates
      else
        []
      end
    end
  end
end
