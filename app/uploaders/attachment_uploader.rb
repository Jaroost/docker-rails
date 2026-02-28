class AttachmentUploader < Shrine
  # Plugins pour ce uploader
  plugin :remove_invalid
  plugin :pretty_location
  plugin :validation_helpers
  plugin :store_dimensions, analyzer: ->(io, analyzers) {
    mime = io.respond_to?(:mime_type) ? io.mime_type : io.content_type
    analyzers[:mini_magick].call(io) if mime&.start_with?("image/")
  }

  # Validations
  Attacher.validate do
    # Taille max 10MB
    validate_max_size 10.megabytes

    # Types MIME autorisés
    validate_mime_type %w[
      image/jpeg
      image/png
      image/gif
      image/webp
      application/pdf
    ]
  end

  # Générer des dérivés pour les images
  Attacher.derivatives do |original|
    next unless image?(original)

    magick = ImageProcessing::MiniMagick.source(original)

    {
      thumbnail: magick.resize_to_limit!(200, 200),
      medium: magick.resize_to_limit!(800, 800)
    }
  end

  private

  def self.image?(file)
    file.mime_type.start_with?("image/")
  end
end
