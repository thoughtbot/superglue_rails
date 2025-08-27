# This file was ported from the amazing folks at turbo-rails
# You can find its MIT License here: https://github.com/hotwired/turbo-rails/blob/main/MIT-LICENSE

class Superglue::StreamsChannel < ActionCable::Channel::Base
  extend Superglue::Streams::StreamName
  extend Superglue::Streams::Broadcasts
  include Superglue::Streams::StreamName::ClassMethods

  def subscribed
    if stream_name = verified_stream_name_from_params
      stream_from stream_name
    else
      reject
    end
  end
end
