# This file was ported from the amazing folks at turbo-rails
# You can find its MIT License here: https://github.com/hotwired/turbo-rails/blob/main/MIT-LICENSE

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
