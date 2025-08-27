# This file was ported from the amazing folks at turbo-rails
# You can find its MIT License here: https://github.com/hotwired/turbo-rails/blob/main/MIT-LICENSE

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
    elsif value.respond_to?(:broadcast_target_default)
      value.broadcast_target_default
    else
      value.to_s
    end
  end

  def broadcast_prepend_props(model: nil, target: nil, save_target: nil, options: {}, **rendering)
    if save_target
      options[:saveAs] ||= fragment_id(save_target)
    end

    broadcast_action_props(action: "prepend", model:, target:, options:, **rendering)
  end

  def broadcast_append_props(model: nil, target: nil, save_target: nil, options: {}, **rendering)
    if save_target
      options[:saveAs] ||= fragment_id(save_target)
    end

    broadcast_action_props(action: "append", model:, target:, options:, **rendering)
  end

  def broadcast_save_props(model: nil, partial: nil, target: nil, options: {}, **rendering)
    if model && !target
      target = fragment_id(model)
    end

    broadcast_action_props(action: "save", model:, target:, options:, **rendering)
  end

  def broadcast_action_props(action:, partial: nil, model: nil, target: nil, options: {}, **rendering)
    if model
      target = model.broadcast_target_default if !target

      if model.respond_to?(:to_partial_path)
        rendering[:locals] = (rendering[:locals] || {}).reverse_merge(model.model_name.element.to_sym => model).compact
        partial ||= model.to_partial_path
      end
    end

    target = fragment_id(target)

    if !partial
      raise StandardError, "A partial is needed to render a stream"
    end

    json = instance_variable_get(:@__json)

    json.child! do
      json.fragmentIds [target]
      json.handler action
      json.options(options)
      json.data(partial: [partial, rendering]) do
      end
    end
  end
end
