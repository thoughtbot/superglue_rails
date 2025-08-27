# This file was ported from the amazing folks at turbo-rails
# You can find its MIT License here: https://github.com/hotwired/turbo-rails/blob/main/MIT-LICENSE

class Superglue::Streams::ActionBroadcastJob < ActiveJob::Base
  discard_on ActiveJob::DeserializationError

  def perform(stream, action:, targets:, options: {}, **rendering)
    Superglue::StreamsChannel.broadcast_action_to stream, action: action, targets: targets, options: options, **rendering
  end
end
