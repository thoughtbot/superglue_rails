class Superglue::Streams::ActionBroadcastJob < ActiveJob::Base
  discard_on ActiveJob::DeserializationError

  def perform(stream, action:, targets:, options: {}, **rendering)
    Superglue::StreamsChannel.broadcast_action_to stream, action: action, targets: targets, options: options, **rendering
  end
end
