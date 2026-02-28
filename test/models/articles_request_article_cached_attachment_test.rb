require "test_helper"

class ArticlesRequestArticleCachedAttachmentTest < ActiveSupport::TestCase
  test "promotes cached attachment when assigning attachment_data" do
    cached_article = ArticlesRequest::Article.new(title: "Tmp", content: "Tmp")
    cached_article.attachment = Rack::Test::UploadedFile.new(
      Rails.root.join("test/fixtures/files/sample.pdf"),
      "application/pdf"
    )

    cached_data = cached_article.attachment_data

    request = ArticlesRequest.create!(title: "Request", description: "Description")
    article = request.articles.build(title: "Valid", content: "Valid")
    article.attachment_data = cached_data

    assert article.attachment_attacher.cached?

    article.save!
    article.reload

    assert article.attachment.present?
    assert_equal :store, article.attachment.storage_key
  end

  test "keeps cached attachment when blank file input is also submitted" do
    cached_article = ArticlesRequest::Article.new(title: "Tmp", content: "Tmp")
    cached_article.attachment = Rack::Test::UploadedFile.new(
      Rails.root.join("test/fixtures/files/sample.pdf"),
      "application/pdf"
    )
    cached_data = cached_article.attachment_data

    request = ArticlesRequest.create!(title: "Request", description: "Description")
    article = request.articles.build(title: "Valid", content: "Valid")
    article.assign_attributes(
      attachment_data: cached_data,
      attachment: ""
    )

    article.save!
    article.reload

    assert article.attachment.present?
    assert_equal :store, article.attachment.storage_key
  end
end
