class SectionChannel < ApplicationCable::Channel
  extend Superglue::Streams::StreamName
  extend Superglue::Streams::Broadcasts
  include Superglue::Streams::StreamName::ClassMethods

  def subscribed
    stream_name = [params[:section], verified_stream_name_from_params].join("_")
    stream_from stream_name
  end
end
