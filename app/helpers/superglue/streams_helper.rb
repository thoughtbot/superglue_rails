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
end
