# ArticlesRequest::Article model
# Namespaced under ArticlesRequest for clean organization
class ArticlesRequest::Article < ApplicationRecord
  # Table name is explicitly set by Rails convention for namespaced models
  # This will use the table: articles_request_articles

  # Enregistrer AVANT le include Shrine pour que ce callback
  # s'exécute avant le before_save de Shrine
  before_save :promote_cached_attachment_if_needed

  # Shrine uploader
  include AttachmentUploader::Attachment(:attachment)

  def attachment_data=(value)
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

  # Quand un fichier en cache est chargé via le champ caché attachment_data
  # (re-soumission après erreur de validation), Shrine ne le marque pas
  # comme "changed" car load_data ne passe pas par change().
  # On force @previous pour que Shrine promeuve le fichier vers le store.
  def promote_cached_attachment_if_needed
    attacher = attachment_attacher
    if attacher.cached? && !attacher.changed?
      attacher.instance_variable_set(:@previous, attacher.dup)
    end
  end
end
