class Superglue::Streams::BroadcastStreamJob < ActiveJob::Base
  discard_on ActiveJob::DeserializationError

  def perform(stream, content:)
    Superglue::StreamsChannel.broadcast_stream_to(stream, content: content)
  end
end
