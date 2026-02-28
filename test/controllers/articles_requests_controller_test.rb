require "test_helper"
require "tempfile"

class ArticlesRequestsControllerTest < ActionDispatch::IntegrationTest
  include ActionDispatch::TestProcess::FixtureFile

  test "creates an articles request with nested article and file" do
    assert_difference("ArticlesRequest.count", 1) do
      assert_difference("ArticlesRequest::Article.count", 1) do
        post articles_requests_url, params: {
          articles_request: {
            title: "Request with file",
            description: "Description",
            articles_attributes: {
              "0" => {
                title: "Article 1",
                content: "Content",
                attachment: fixture_file_upload("sample.pdf", "application/pdf")
              }
            }
          }
        }
      end
    end

    article = ArticlesRequest.last.articles.last
    assert article.attachment.present?
    assert_equal :store, article.attachment.storage_key
  end

  test "persists cached file after validation error then successful resubmit" do
    cached_article = ArticlesRequest::Article.new(title: "Tmp", content: "Tmp")
    cached_article.attachment = fixture_file_upload("sample.pdf", "application/pdf")
    cached_attachment_data = cached_article.attachment_data

    post articles_requests_url, params: {
      articles_request: {
        title: "Invalid first submit",
        description: "Description",
        articles_attributes: {
          "0" => {
            title: "",
            content: "Missing title should fail validation",
            attachment_data: cached_attachment_data
          }
        }
      }
    }

    assert_response :unprocessable_entity
    assert_equal 0, ArticlesRequest.where(title: "Invalid first submit").count

    assert_difference("ArticlesRequest.count", 1) do
      post articles_requests_url, params: {
        articles_request: {
          title: "Valid resubmit",
          description: "Description",
          articles_attributes: {
            "0" => {
              title: "Now valid",
              content: "Content",
              attachment: "",
              attachment_data: cached_attachment_data
            }
          }
        }
      }
    end

    created_article = ArticlesRequest.last.articles.last
    assert created_article.attachment.present?
    assert_equal :store, created_article.attachment.storage_key
  end

  test "re-renders cached attachment_data in hidden field after validation error" do
    post articles_requests_url, params: {
      articles_request: {
        title: "Invalid first submit",
        description: "Description",
        articles_attributes: {
          "0" => {
            title: "Has file",
            content: "",
            attachment: fixture_file_upload("sample.pdf", "application/pdf")
          }
        }
      }
    }

    assert_response :unprocessable_entity
    assert_includes @response.body, 'name="articles_request[articles_attributes][0][attachment_data]"'
    assert_includes @response.body, '&quot;storage&quot;:&quot;cache&quot;'
  end

  test "persists cached file when browser sends empty multipart upload" do
    cached_article = ArticlesRequest::Article.new(title: "Tmp", content: "Tmp")
    cached_article.attachment = fixture_file_upload("sample.pdf", "application/pdf")
    cached_attachment_data = cached_article.attachment_data

    empty_upload = ActionDispatch::Http::UploadedFile.new(
      tempfile: Tempfile.new("empty-upload"),
      filename: "",
      type: "application/octet-stream"
    )

    assert_difference("ArticlesRequest.count", 1) do
      post articles_requests_url, params: {
        articles_request: {
          title: "Valid with empty multipart upload",
          description: "Description",
          articles_attributes: {
            "0" => {
              title: "Now valid",
              content: "Content",
              attachment: empty_upload,
              attachment_data: cached_attachment_data
            }
          }
        }
      }
    end

    created_article = ArticlesRequest.last.articles.last
    assert created_article.attachment.present?
    assert_equal :store, created_article.attachment.storage_key
  end
end
