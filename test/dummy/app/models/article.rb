class Article < ApplicationRecord
  include Superglue::Broadcastable

  has_many :comments

  validates :body, presence: true

  broadcasts "overriden-stream", fragment: "overriden-fragment"

  def to_gid_param
    to_param
  end

  def to_param
    body.parameterize
  end
end
