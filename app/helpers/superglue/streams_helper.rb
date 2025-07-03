module Superglue::StreamsHelper
  def stream_from_props(*streamables, **attributes)
    raise ArgumentError, "streamables can't be blank" unless streamables.any?(&:present?)
    attributes[:channel] = attributes[:channel]&.to_s || "Superglue::StreamsChannel"
    attributes[:signed_stream_name] = Superglue::StreamsChannel.signed_stream_name(streamables)

    attributes
  end

  def fragment_id(value)
    if value.respond_to?(:to_key)
      ActionView::RecordIdentifier.dom_id(value)
    elsif value.respond_to?(:broadcast_fragment_default)
      value.broadcast_fragment_default
    else
      value.to_s
    end
  end

  def broadcast_prepend_props(model: nil, fragment: nil, save_as: nil, options: {}, **rendering)
    if save_as
      options[:saveAs] ||= fragment_id(save_as)
    end

    broadcast_action_props(action: "prepend", model:, fragment:, options:, **rendering)
  end

  def broadcast_append_props(model: nil, fragment: nil, save_as: nil, options: {}, **rendering)
    if save_as
      options[:saveAs] ||= fragment_id(save_as)
    end

    broadcast_action_props(action: "append", model:, fragment:, options:, **rendering)
  end

  def broadcast_save_props(model: nil, partial: nil, fragment: nil, options: {}, **rendering)
    broadcast_action_props(action: "save", model:, fragment:, options:, **rendering)
  end

  def broadcast_action_props(action:, partial: nil, model: nil, fragment: nil, options: {}, **rendering)
    if model
      fragment = model.broadcast_fragment_default if !fragment

      if model.respond_to?(:to_partial_path)
        rendering[:locals] = (rendering[:locals] || {}).reverse_merge(model.model_name.element.to_sym => model).compact
        partial ||= model.to_partial_path
      end
    end

    fragment = fragment_id(fragment)

    if !partial
      raise StandardError, "A partial is needed to render a stream"
    end

    json = instance_variable_get(:@__json)

    json.child! do
      json.fragmentKeys [fragment]
      json.action action
      json.options(options)
      json.data(partial: [partial, rendering]) do
      end
    end
  end
end
