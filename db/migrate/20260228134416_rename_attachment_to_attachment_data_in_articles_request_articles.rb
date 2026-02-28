class RenameAttachmentToAttachmentDataInArticlesRequestArticles < ActiveRecord::Migration[8.1]
  def change
    rename_column :articles_request_articles, :attachment, :attachment_data
  end
end
