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
