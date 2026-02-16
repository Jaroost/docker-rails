require "shrine"
require "shrine/storage/file_system"

# Configuration Shrine pour le stockage local
Shrine.storages = {
  cache: Shrine::Storage::FileSystem.new("public", prefix: "uploads/cache"),
  store: Shrine::Storage::FileSystem.new("public", prefix: "uploads/store")
}

# Plugin pour la validation
Shrine.plugin :activerecord
Shrine.plugin :cached_attachment_data
Shrine.plugin :restore_cached_data
Shrine.plugin :determine_mime_type
Shrine.plugin :validation_helpers
Shrine.plugin :remove_attachment

# Support des images
Shrine.plugin :derivatives
Shrine.plugin :default_url
