require "test_helper"

class ArticlesRequestsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get articles_requests_index_url
    assert_response :success
  end

  test "should get show" do
    get articles_requests_show_url
    assert_response :success
  end

  test "should get new" do
    get articles_requests_new_url
    assert_response :success
  end

  test "should get create" do
    get articles_requests_create_url
    assert_response :success
  end

  test "should get edit" do
    get articles_requests_edit_url
    assert_response :success
  end

  test "should get update" do
    get articles_requests_update_url
    assert_response :success
  end

  test "should get destroy" do
    get articles_requests_destroy_url
    assert_response :success
  end
end
