# ArticlesRequest::Article model
# Namespaced under ArticlesRequest for clean organization
class ArticlesRequest::Article < ApplicationRecord
  # Table name is explicitly set by Rails convention for namespaced models
  # This will use the table: articles_request_articles

  # Shrine uploader
  include AttachmentUploader::Attachment(:attachment)

  # Association
  belongs_to :articles_request,
    class_name: "::ArticlesRequest",
    foreign_key: "articles_request_id", optional: true

  # Validations
  validates :title, presence: true
  validates :content, presence: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_title, -> { order(:title) }
end
