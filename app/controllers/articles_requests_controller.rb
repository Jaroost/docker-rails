class ArticlesRequestsController < ApplicationController
  before_action :set_articles_request, only: [:show, :edit, :update, :destroy]

  # GET /articles_requests
  def index
    @articles_requests = ArticlesRequest.includes(:articles).order(created_at: :desc)
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
  end

  def articles_request_params
    params.require(:articles_request).permit(
      :title,
      :description,
      articles_attributes: [:id, :title, :content, :_destroy]
    )
  end
end
