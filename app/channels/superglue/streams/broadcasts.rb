module Turbo::Streams::Broadcasts
  include Turbo::Streams::ActionHelper

  def broadcast_replace_to(*streamables, **opts)
    broadcast_action_to(*streamables, action: :replace, **opts)
  end

  def broadcast_update_to(*streamables, **opts)
    broadcast_action_to(*streamables, action: :update, **opts)
  end

  def broadcast_append_to(*streamables, **opts)
    broadcast_action_to(*streamables, action: :append, **opts)
  end

  def broadcast_prepend_to(*streamables, **opts)
    broadcast_action_to(*streamables, action: :prepend, **opts)
  end

  def broadcast_refresh_to(*streamables, **opts)
    broadcast_stream_to(*streamables, content: turbo_stream_refresh_tag)
  end

  def broadcast_action_to(*streamables, action:, target: nil, targets: nil, options: {}, **rendering)
    broadcast_stream_to(*streamables, content: turbo_stream_action_tag(
      action, target: target, targets: targets, template: render_broadcast_action(rendering), **options)
    )
  end

  def broadcast_replace_later_to(*streamables, **opts)
    broadcast_action_later_to(*streamables, action: :replace, **opts)
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

  def broadcast_refresh_later_to(*streamables, request_id: Turbo.current_request_id, **opts)
    stream_name = stream_name_from(streamables)

    refresh_debouncer_for(*streamables, request_id: request_id).debounce do
      Turbo::Streams::BroadcastStreamJob.perform_later stream_name, content: turbo_stream_refresh_tag(request_id: request_id, **opts).to_str # Sidekiq requires job arguments to be valid JSON types, such as String
    end
  end

  def broadcast_action_later_to(*streamables, action:, target: nil, targets: nil, options: {}, **rendering)
    streamables.flatten!
    streamables.compact_blank!

    if streamables.present?
      target = convert_to_turbo_stream_dom_id(target)
      targets = convert_to_turbo_stream_dom_id(targets, include_selector: true)
      Turbo::Streams::ActionBroadcastJob.perform_later \
        stream_name_from(streamables), action: action, target: target, targets: targets, options: options, **rendering
    end
  end

  def broadcast_stream_to(*streamables, content:)
    streamables.flatten!
    streamables.compact_blank!

    if streamables.present?
      ActionCable.server.broadcast stream_name_from(streamables), content
    end
  end

  def refresh_debouncer_for(*streamables, request_id: nil) # :nodoc:
    Turbo::ThreadDebouncer.for("turbo-refresh-debouncer-#{stream_name_from(streamables.including(request_id))}")
  end

  private
    def render_format(format, **rendering)
      ApplicationController.render(formats: [ format ], **rendering)
    end

    def render_broadcast_action(rendering)
      content = rendering.delete(:content)
      html    = rendering.delete(:html)
      
      content || html || (render_format(:html, **rendering) if rendering.present?)
    end
end
