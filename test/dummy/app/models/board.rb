class Board < ApplicationRecord
  include Superglue::Broadcastable
  broadcasts_refreshes
end
