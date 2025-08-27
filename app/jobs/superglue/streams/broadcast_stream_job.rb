# This file was ported from the amazing folks at turbo-rails
# You can find its MIT License here: https://github.com/hotwired/turbo-rails/blob/main/MIT-LICENSE

class Superglue::Streams::BroadcastStreamJob < ActiveJob::Base
  discard_on ActiveJob::DeserializationError

  def perform(stream, content:)
    Superglue::StreamsChannel.broadcast_stream_to(stream, content: content)
  end
end
