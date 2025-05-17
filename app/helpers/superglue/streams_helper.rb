module Turbo::StreamsHelper
  def turbo_stream
    Turbo::Streams::TagBuilder.new(self)
  end

  def turbo_stream_from(*streamables, **attributes)
    raise ArgumentError, "streamables can't be blank" unless streamables.any?(&:present?)
    attributes[:channel] = attributes[:channel]&.to_s || "Turbo::StreamsChannel"
    attributes[:"signed-stream-name"] = Turbo::StreamsChannel.signed_stream_name(streamables)

    tag.turbo_cable_stream_source(**attributes)
  end
end
