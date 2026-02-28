require "test_helper"
require "tempfile"

class ArticlesRequestsControllerTest < ActionDispatch::IntegrationTest
  include ActionDispatch::TestProcess::FixtureFile

  setup do
    @admin = User.create!(
      provider: "keycloak",
      uid: "admin-test-uid",
      email: "admin-tests@example.com",
      username: "admin_tests",
      first_name: "Admin",
      last_name: "Tests",
      role: :admin
    )

    @reader = User.create!(
      provider: "keycloak",
      uid: "reader-test-uid",
      email: "reader-tests@example.com",
      username: "reader_tests",
      first_name: "Reader",
      last_name: "Tests",
      role: :reader
    )
  end

  test "creates an articles request with nested article and file" do
    sign_in @admin

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
    sign_in @admin

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
    sign_in @admin

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
    sign_in @admin

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

  test "reader can view index and show but cannot access new/edit" do
    request_record = ArticlesRequest.create!(title: "Visible", description: "Reader can read")
    request_record.articles.create!(title: "Article", content: "Content")

    sign_in @reader

    get articles_requests_url
    assert_response :success

    get articles_request_url(request_record)
    assert_response :success

    get new_articles_request_url
    assert_redirected_to root_url

    get edit_articles_request_url(request_record)
    assert_redirected_to root_url
  end

  test "reader cannot create update or destroy" do
    request_record = ArticlesRequest.create!(title: "Keep", description: "Cannot modify")
    request_record.articles.create!(title: "Article", content: "Content")

    sign_in @reader

    assert_no_difference("ArticlesRequest.count") do
      post articles_requests_url, params: {
        articles_request: {
          title: "Should not create",
          description: "Denied",
          articles_attributes: {
            "0" => { title: "A", content: "B" }
          }
        }
      }
    end
    assert_redirected_to root_url

    patch articles_request_url(request_record), params: {
      articles_request: {
        title: "Changed by reader"
      }
    }
    assert_redirected_to root_url
    assert_not_equal "Changed by reader", request_record.reload.title

    assert_no_difference("ArticlesRequest.count") do
      delete articles_request_url(request_record)
    end
    assert_redirected_to root_url
  end
end
