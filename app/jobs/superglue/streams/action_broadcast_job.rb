class Turbo::Streams::ActionBroadcastJob < ActiveJob::Base
  discard_on ActiveJob::DeserializationError
  
  def perform(stream, action:, target:, attributes: {}, **rendering)
    Turbo::StreamsChannel.broadcast_action_to stream, action: action, target: target, attributes: attributes, **rendering
  end
end
