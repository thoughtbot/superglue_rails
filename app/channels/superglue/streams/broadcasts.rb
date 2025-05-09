# Provides the broadcast actions in synchronous and asynchronous form for the <tt>Superglue::StreamsChannel</tt>.
# See <tt>Superglue::Broadcastable</tt> for the user-facing API that invokes these methods with most of the paperwork filled out already.
#
# Can be used directly using something like <tt>Superglue::StreamsChannel.broadcast_remove_to :entries, target: 1</tt>.
module Superglue::Streams::Broadcasts
  # include Superglue::Streams::ActionHelper

  # def broadcast_remove_to(*streamables, **opts)
  #   broadcast_action_to(*streamables, action: :remove, render: false, **opts)
  # end

  def broadcast_replace_to(*streamables, **opts)
    broadcast_action_to(*streamables, action: :replace, **opts)
  end

  # def broadcast_update_to(*streamables, **opts)
  #   broadcast_action_to(*streamables, action: :update, **opts)
  # end

  # def broadcast_before_to(*streamables, **opts)
  #   broadcast_action_to(*streamables, action: :before, **opts)
  # end

  # def broadcast_after_to(*streamables, **opts)
  #   broadcast_action_to(*streamables, action: :after, **opts)
  # end

  # def broadcast_append_to(*streamables, **opts)
  #   broadcast_action_to(*streamables, action: :append, **opts)
  # end

  # def broadcast_prepend_to(*streamables, **opts)
  #   broadcast_action_to(*streamables, action: :prepend, **opts)
  # end

  # def broadcast_refresh_to(*streamables, **opts)
  #   broadcast_stream_to(*streamables, content: superglue_stream_refresh_tag)
  # end

  def broadcast_action_to(*streamables, action:, target: nil, targets: nil, attributes: {}, **rendering)
    broadcast_stream_to(*streamables, content: render_broadcast_action(rendering))
  end

  # def broadcast_replace_later_to(*streamables, **opts)
  #   broadcast_action_later_to(*streamables, action: :replace, **opts)
  # end

  # def broadcast_update_later_to(*streamables, **opts)
  #   broadcast_action_later_to(*streamables, action: :update, **opts)
  # end

  # def broadcast_before_later_to(*streamables, **opts)
  #   broadcast_action_later_to(*streamables, action: :before, **opts)
  # end

  # def broadcast_after_later_to(*streamables, **opts)
  #   broadcast_action_later_to(*streamables, action: :after, **opts)
  # end

  # def broadcast_append_later_to(*streamables, **opts)
  #   broadcast_action_later_to(*streamables, action: :append, **opts)
  # end

  # def broadcast_prepend_later_to(*streamables, **opts)
  #   broadcast_action_later_to(*streamables, action: :prepend, **opts)
  # end

  # def broadcast_refresh_later_to(*streamables, request_id: Superglue.current_request_id, **opts)
  #   stream_name = stream_name_from(streamables)

  #   refresh_debouncer_for(*streamables, request_id: request_id).debounce do
  #     Superglue::Streams::BroadcastStreamJob.perform_later stream_name, content: superglue_stream_refresh_tag(request_id: request_id, **opts).to_str # Sidekiq requires job arguments to be valid JSON types, such as String
  #   end
  # end

  # def broadcast_action_later_to(*streamables, action:, target: nil, targets: nil, attributes: {}, **rendering)
  #   streamables.flatten!
  #   streamables.compact_blank!

  #   return unless streamables.present?

  #   target = convert_to_superglue_stream_dom_id(target)
  #   targets = convert_to_superglue_stream_dom_id(targets, include_selector: true)
  #   Superglue::Streams::ActionBroadcastJob.perform_later \
  #     stream_name_from(streamables), action: action, target: target, targets: targets, attributes: attributes, **rendering
  # end

  # def broadcast_render_to(*streamables, **rendering)
  #   broadcast_stream_to(*streamables, content: render_format(:superglue_stream, **rendering))
  # end

  # def broadcast_render_later_to(*streamables, **rendering)
  #   Superglue::Streams::BroadcastJob.perform_later stream_name_from(streamables), **rendering
  # end

  def broadcast_stream_to(*streamables, content:)
    streamables.flatten!
    streamables.compact_blank!

    return unless streamables.present?

    ActionCable.server.broadcast stream_name_from(streamables), content
  end

  # def refresh_debouncer_for(*streamables, request_id: nil) # :nodoc:
  #   Superglue::ThreadDebouncer.for("superglue-refresh-debouncer-#{stream_name_from(streamables.including(request_id))}")
  # end

  private

  def render_format(format, **rendering)
    rendering[:layout] = "superglue/layouts/fragment"
    ApplicationController.render(formats: [format], **rendering)
  end

  def render_broadcast_action(rendering)
    content = rendering.delete(:content)
    html    = rendering.delete(:html)
    render  = rendering.delete(:render)

    if render == false
      nil
    else
      content || html || (render_format(:json, **rendering) if rendering.present?)
    end
  end
end
