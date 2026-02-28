# ArticlesRequest::Article model
# Namespaced under ArticlesRequest for clean organization
class ArticlesRequest::Article < ApplicationRecord
  # Table name is explicitly set by Rails convention for namespaced models
  # This will use the table: articles_request_articles

  # Ensure cached files from hidden attachment_data are promoted on valid save.
  before_save :promote_cached_attachment_if_needed

  # Shrine uploader
  include AttachmentUploader::Attachment(:attachment)

  def attachment=(value)
    if value.respond_to?(:original_filename) && value.original_filename.blank?
      # Ignore empty multipart uploads sent by browsers.
      return
    end
    if value.is_a?(String) && value.start_with?("#<ActionDispatch::Http::UploadedFile")
      return
    end
    return if value.is_a?(String) && value.blank?

    super(value)
  end

  def attachment_data=(value)
    # Defensive guard: ignore accidental uploaded-file object assignment.
    if value.respond_to?(:original_filename) && value.original_filename.present?
      return
    end
    if value.is_a?(String) && value.start_with?("#<ActionDispatch::Http::UploadedFile")
      return
    end

    super(value.presence)
  end

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

  private

  def promote_cached_attachment_if_needed
    attacher = attachment_attacher
    attacher.promote if attacher.cached?
  end
end
