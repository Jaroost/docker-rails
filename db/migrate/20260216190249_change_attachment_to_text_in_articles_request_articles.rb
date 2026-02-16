class ChangeAttachmentToTextInArticlesRequestArticles < ActiveRecord::Migration[8.1]
  def change
    change_column :articles_request_articles, :attachment, :text
  end
end
