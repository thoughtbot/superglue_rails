# This file was ported from the amazing folks at turbo-rails
# You can find its MIT License here: https://github.com/hotwired/turbo-rails/blob/main/MIT-LICENSE

module Superglue::Streams::Broadcasts
  def broadcast_update_to(*streamables, **opts)
    broadcast_action_to(*streamables, action: :update, **opts)
  end

  def broadcast_append_to(*streamables, **opts)
    broadcast_action_to(*streamables, action: :append, **opts)
  end

  def broadcast_prepend_to(*streamables, **opts)
    broadcast_action_to(*streamables, action: :prepend, **opts)
  end

  def broadcast_action_to(*streamables, action:, target: nil, targets: nil, save_target: nil, options: {}, **rendering)
    locals = rendering[:locals] || {}
    targets = (target ? [target] : targets)

    targets = targets.map do |item|
      convert_to_superglue_fragment_id(item)
    end

    if save_target
      options[:saveAs] = convert_to_superglue_fragment_id(save_target)
    end

    locals[:broadcast_target_keys] = targets
    locals[:broadcast_action] = action
    locals[:broadcast_options] = options
    rendering[:locals] = locals

    broadcast_stream_to(*streamables, content: render_broadcast_action(rendering))
  end

  def broadcast_update_later_to(*streamables, **opts)
    broadcast_action_later_to(*streamables, action: :update, **opts)
  end

  def broadcast_append_later_to(*streamables, **opts)
    broadcast_action_later_to(*streamables, action: :append, **opts)
  end

  def broadcast_prepend_later_to(*streamables, **opts)
    broadcast_action_later_to(*streamables, action: :prepend, **opts)
  end

  def broadcast_action_later_to(*streamables, action:, target: nil, targets: nil, save_target: nil, options: {}, **rendering)
    streamables.flatten!
    streamables.compact_blank!

    return unless streamables.present?

    targets = (target ? [target] : targets).map do |item|
      convert_to_superglue_fragment_id(item)
    end

    if save_target
      options[:saveAs] = convert_to_superglue_fragment_id(save_target)
    end

    Superglue::Streams::ActionBroadcastJob.perform_later \
      stream_name_from(streamables), action: action, targets: targets, options: options, **rendering
  end

  def broadcast_stream_to(*streamables, content:)
    streamables.flatten!
    streamables.compact_blank!

    return unless streamables.present?

    ActionCable.server.broadcast stream_name_from(streamables), content
  end

  private

  def convert_to_superglue_fragment_id(target)
    target_array = Array.wrap(target)
    if target_array.any? { |value| value.respond_to?(:to_key) }
      ActionView::RecordIdentifier.dom_id(*target_array)
    else
      target
    end
  end

  def render_format(format, **rendering)
    rendering[:layout] = "superglue/layouts/stream_message"
    ApplicationController.render(formats: [format], **rendering)
  end

  def render_broadcast_action(rendering)
    json = rendering.delete(:json)

    if json
      rendering[:locals] ||= {}
      rendering[:locals][:broadcast_json] = json
    end

    render_format(:json, **rendering)
  end
end
