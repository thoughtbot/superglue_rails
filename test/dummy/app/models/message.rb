class Message < ApplicationRecord
  include Superglue::Broadcastable
  delegate :to_s, to: :content, allow_nil: true
end
