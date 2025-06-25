class Comment < ApplicationRecord
  include Superglue::Broadcastable
  belongs_to :article

  validates :body, presence: true

  broadcasts_to ->(comment) { [comment.article, :comments] },
    fragment: ->(comment) { "article_#{comment.article_id}_comments" },
    partial: "comments/different_comment",
    locals: {highlight: true}
end
