class Turbo::Streams::BroadcastJob < ActiveJob::Base
  discard_on ActiveJob::DeserializationError

  def perform(stream, **rendering)
    Turbo::StreamsChannel.broadcast_render_to stream, **rendering
  end
end
