class Superglue::Streams::ActionBroadcastJob < ActiveJob::Base
  discard_on ActiveJob::DeserializationError

  def perform(stream, action:, fragments:, options: {}, **rendering)
    Superglue::StreamsChannel.broadcast_action_to stream, action: action, fragments: fragments, options: options, **rendering
  end
end
