# Main ArticlesRequest model
class ArticlesRequest < ApplicationRecord
  # Associations
  has_many :articles,
    class_name: "ArticlesRequest::Article",
    foreign_key: "articles_request_id",
    dependent: :destroy

  # Nested attributes
  accepts_nested_attributes_for :articles,
    allow_destroy: true,
    reject_if: :all_blank

  # Validations
  validates :title, presence: true
  validates :description, presence: true
end
