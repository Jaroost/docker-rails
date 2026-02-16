class AddAttachmentToArticlesRequestArticles < ActiveRecord::Migration[8.1]
  def change
    add_column :articles_request_articles, :attachment, :string
  end
end
