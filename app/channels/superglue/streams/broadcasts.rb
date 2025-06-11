module Superglue::Streams::Broadcasts
  def broadcast_replace_to(*streamables, **opts)
    broadcast_action_to(*streamables, action: :replace, **opts)
  end

  def broadcast_append_to(*streamables, **opts)
    broadcast_action_to(*streamables, action: :append, **opts)
  end

  def broadcast_prepend_to(*streamables, **opts)
    broadcast_action_to(*streamables, action: :prepend, **opts)
  end

  def broadcast_refresh_to(*streamables, **opts)
    request_id = Superglue.current_request_id
    content = JSON.generate({
      type: "message",
      action: "refresh",
      requestId: request_id,
      options: opts
    })
    broadcast_stream_to(*streamables, content: content)
  end

  def broadcast_action_to(*streamables, action:, target: nil, targets: nil, options: {}, **rendering)
    locals = rendering[:locals] || {}
    targets = (target ? [target] : targets)

    targets = targets.map do |item|
      convert_to_superglue_fragment_id(item)
    end

    locals[:broadcast_targets] = targets
    locals[:broadcast_action] = action
    locals[:broadcast_options] = options
    rendering[:locals] = locals

    broadcast_stream_to(*streamables, content: render_broadcast_action(rendering))
  end

  def broadcast_replace_later_to(*streamables, **opts)
    broadcast_action_later_to(*streamables, action: :replace, **opts)
  end

  #todo convert_to_turbo_stream_dom_id ican use this as the fragment name!

  def broadcast_append_later_to(*streamables, **opts)
    broadcast_action_later_to(*streamables, action: :append, **opts)
  end

  def broadcast_prepend_later_to(*streamables, **opts)
    broadcast_action_later_to(*streamables, action: :prepend, **opts)
  end

  def broadcast_refresh_later_to(*streamables, request_id: Superglue.current_request_id, **opts)
    stream_name = stream_name_from(streamables)

    refresh_debouncer_for(*streamables, request_id: request_id).debounce do
      content = JSON.generate({
        type: "message",
        action: "refresh",
        requestId: request_id,
        options: opts
      })

      Superglue::Streams::BroadcastStreamJob.perform_later stream_name, content: content
    end
  end

  def broadcast_action_later_to(*streamables, action:, target: nil, targets: nil, options: {}, **rendering)
    streamables.flatten!
    streamables.compact_blank!

    return unless streamables.present?

    targets = (target ? [target] : targets).map do |item|
      convert_to_superglue_fragment_id(item)
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

  def refresh_debouncer_for(*streamables, request_id: nil) # :nodoc:
    Superglue::ThreadDebouncer.for("superglue-refresh-debouncer-#{stream_name_from(streamables.including(request_id))}")
  end

  private

  def convert_to_superglue_fragment_id(target, include_selector: false)
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
    render = rendering.delete(:render)
    json = rendering.delete(:json)

    # todo: remove
    if render == false
      nil
    elsif rendering.present?
      if json
        rendering[:locals] ||= {}
        rendering[:locals][:broadcast_json] = json
      end

      render_format(:json, **rendering)
    end
  end
end
