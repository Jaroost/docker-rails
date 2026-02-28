class ArticlesRequestsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_articles_request, only: [:show, :edit, :update, :destroy]
  before_action :authorize_articles_request_class, only: [:new, :create]
  after_action :verify_authorized, except: [:index]
  after_action :verify_policy_scoped, only: [:index]

  # GET /articles_requests
  def index
    @articles_requests = policy_scope(ArticlesRequest).includes(:articles).order(created_at: :desc)
  end

  # GET /articles_requests/:id
  def show
  end

  # GET /articles_requests/new
  def new
    @articles_request = ArticlesRequest.new
    # Build 3 empty articles for the form
    3.times { @articles_request.articles.build }
  end

  # GET /articles_requests/:id/edit
  def edit
    # Build at least one empty article for adding new ones
    @articles_request.articles.build if @articles_request.articles.empty?
  end

  # POST /articles_requests
  def create
    @articles_request = ArticlesRequest.new(articles_request_params)

    if @articles_request.save
      redirect_to @articles_request, notice: "Articles request was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /articles_requests/:id
  def update
    if @articles_request.update(articles_request_params)
      redirect_to @articles_request, notice: "Articles request was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /articles_requests/:id
  def destroy
    @articles_request.destroy
    redirect_to articles_requests_url, notice: "Articles request was successfully destroyed."
  end

  private

  def set_articles_request
    @articles_request = ArticlesRequest.find(params[:id])
    authorize @articles_request
  end

  def authorize_articles_request_class
    authorize ArticlesRequest
  end

  def articles_request_params
    permitted = params.require(:articles_request).permit(
      :title,
      :description,
      articles_attributes: [:id, :title, :content, :attachment, :attachment_data, :_destroy]
    )

    # Browser resubmits file inputs as blank strings after validation errors.
    # Keep cached Shrine attachment_data by dropping empty attachment values.
    if permitted[:articles_attributes].present?
      permitted[:articles_attributes].each_value do |article_attrs|
        attachment_param = article_attrs[:attachment] || article_attrs["attachment"]
        remove_attachment =
          if attachment_param.respond_to?(:original_filename)
            # Empty multipart file field from browser submit
            attachment_param.original_filename.blank?
          else
            attachment_param.blank?
          end

        if remove_attachment
          article_attrs.delete(:attachment)
          article_attrs.delete("attachment")
        end
      end
    end

    permitted
  end
end
