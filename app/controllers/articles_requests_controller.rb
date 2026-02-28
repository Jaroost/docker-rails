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
    log_attachment_debug("create", "before_permit", raw_articles_attributes)
    permitted = articles_request_params
    log_attachment_debug("create", "after_permit", permitted[:articles_attributes])

    @articles_request = ArticlesRequest.new(permitted)

    if @articles_request.save
      log_saved_attachments("create", @articles_request)
      redirect_to @articles_request, notice: "Articles request was successfully created."
    else
      log_saved_attachments("create_invalid", @articles_request)
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /articles_requests/:id
  def update
    log_attachment_debug("update", "before_permit", raw_articles_attributes)
    permitted = articles_request_params
    log_attachment_debug("update", "after_permit", permitted[:articles_attributes])

    if @articles_request.update(permitted)
      log_saved_attachments("update", @articles_request)
      redirect_to @articles_request, notice: "Articles request was successfully updated."
    else
      log_saved_attachments("update_invalid", @articles_request)
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

  def raw_articles_attributes
    articles_request = params[:articles_request]
    return {} unless articles_request.respond_to?(:[])

    articles_request[:articles_attributes] || articles_request["articles_attributes"] || {}
  end

  def log_attachment_debug(action_name, phase, attributes_hash)
    rows = normalize_articles_attributes(attributes_hash).map do |key, attrs|
      attachment = attrs[:attachment]
      attachment_data = attrs[:attachment_data]

      {
        key: key,
        id: attrs[:id],
        title_present: attrs[:title].present?,
        destroy: attrs[:_destroy],
        attachment_class: attachment.class.name,
        attachment_blank: attachment.respond_to?(:blank?) ? attachment.blank? : attachment.nil?,
        attachment_filename: attachment.respond_to?(:original_filename) ? attachment.original_filename : nil,
        attachment_data_present: attachment_data.present?,
        attachment_data_size: attachment_data.is_a?(String) ? attachment_data.bytesize : nil,
        attachment_data_cached_id: extract_cached_id(attachment_data),
        attachment_data_filename: extract_cached_filename(attachment_data)
      }
    end

    Rails.logger.info(
      "[TEMP ATTACH DEBUG] action=#{action_name} phase=#{phase} request_id=#{request.request_id} rows=#{rows.to_json}"
    )
  end

  def log_saved_attachments(action_name, articles_request)
    rows = articles_request.articles.map do |article|
      {
        id: article.id,
        title: article.title,
        valid: article.valid?,
        errors: article.errors.full_messages,
        attachment_present: article.attachment.present?,
        attachment_storage: article.attachment&.storage_key,
        attachment_data_present: article.attachment_data.present?,
        attachment_data_size: article.attachment_data&.bytesize
      }
    end

    Rails.logger.info(
      "[TEMP ATTACH DEBUG] action=#{action_name} phase=after_save request_id=#{request.request_id} persisted=#{articles_request.persisted?} rows=#{rows.to_json}"
    )
  end

  def normalize_articles_attributes(attributes_hash)
    return [] if attributes_hash.blank?

    source_hash =
      if attributes_hash.respond_to?(:to_unsafe_h)
        attributes_hash.to_unsafe_h
      elsif attributes_hash.respond_to?(:to_h)
        attributes_hash.to_h
      else
        {}
      end

    source_hash.map do |key, value|
      attrs = if value.respond_to?(:to_unsafe_h)
               value.to_unsafe_h
      elsif value.respond_to?(:to_h)
               value.to_h
      else
               {}
      end

      [key, attrs.with_indifferent_access]
    end
  end

  def extract_cached_id(attachment_data)
    parsed = parse_attachment_data(attachment_data)
    parsed["id"]
  end

  def extract_cached_filename(attachment_data)
    parsed = parse_attachment_data(attachment_data)
    parsed.dig("metadata", "filename")
  end

  def parse_attachment_data(attachment_data)
    return {} unless attachment_data.is_a?(String) && attachment_data.present?

    JSON.parse(attachment_data)
  rescue JSON::ParserError
    {}
  end
end
