module Superglue::StreamsHelper
  # todo: add fragment_id
  def stream_from_props(*streamables, **attributes)
    raise ArgumentError, "streamables can't be blank" unless streamables.any?(&:present?)
    attributes[:channel] = attributes[:channel]&.to_s || "Superglue::StreamsChannel"
    attributes[:signed_stream_name] = Superglue::StreamsChannel.signed_stream_name(streamables)

    attributes
  end
end
