module Turbo::Streams::StreamName
  def verified_stream_name(signed_stream_name)
    Turbo.signed_stream_verifier.verified signed_stream_name
  end

  def signed_stream_name(streamables)
    Turbo.signed_stream_verifier.generate stream_name_from(streamables)
  end

  module ClassMethods
    def verified_stream_name_from_params
      self.class.verified_stream_name(params[:signed_stream_name])
    end
  end

  private
    def stream_name_from(streamables)
      if streamables.is_a?(Array)
        streamables.map  { |streamable| stream_name_from(streamable) }.join(":")
      else
        streamables.then { |streamable| streamable.try(:to_gid_param) || streamable.to_param }
      end
    end
end
