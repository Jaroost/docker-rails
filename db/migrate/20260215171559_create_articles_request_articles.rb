class CreateArticlesRequestArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :articles_request_articles do |t|
      t.string :title
      t.text :content
      t.references :articles_request, null: false, foreign_key: true

      t.timestamps
    end
  end
end
