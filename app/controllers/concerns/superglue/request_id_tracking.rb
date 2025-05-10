module Superglue::RequestIdTracking
  extend ActiveSupport::Concern

  included do
    around_action :superglue_tracking_request_id
  end

  private

  def superglue_tracking_request_id(&block)
    Superglue.with_request_id(request.headers["X-Superglue-Request-Id"], &block)
  end
end
