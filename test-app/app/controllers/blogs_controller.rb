# frozen_string_literal: true

require 'fileutils'

class BlogsController < ApplicationController
  # POST /blogs
  def create
    @blog = Blog.create(params.require(:blog).permit(:title, :content))
    respond_with @blog
  end

  # POST /blogs/flexible
  def flexible_create
    # contrived example to play around with new anyOf and oneOf
    # request body definition for 3.0
    blog_params = params.require(:blog).permit(:title, :content, :headline, :text)

    @blog = Blog.create(blog_params)
    respond_with @blog
  end

  # POST /blogs/alternate
  def alternate_create
    # contrived example to show different :examples in the requestBody section
    @blog = Blog.create(params.require(:blog).permit(:title, :content))
    respond_with @blog
  end

  # Put /blogs/1
  def upload
    @blog = Blog.find_by_id(params[:id])
    return head :not_found if @blog.nil?

    @blog.thumbnail = save_uploaded_file params[:file]
    head @blog.save ? :ok : :unprocessable_entity
  end

  def download
    @blog = Blog.find_by_id(params[:id])

    if @blog.nil?
      head :not_found
    elsif @blog.thumbnail.blank?
      body = { errors: { messages: ['No thumbnail available for selected blog'] } }
      render json: body, status: :unprocessable_entity
    else
      send_file File.join('public/uploads', @blog.thumbnail), filename: @blog.thumbnail, disposition: 'attachment'
    end
  end

  # GET /blogs
  def index
    @blogs = Blog.all
    @blogs = @blogs.where(status: params[:status]) if params[:status].present?

    if search_filters[:date_from]
      @blogs = @blogs.where(created_at: search_filters[:date_from]..)
    end
    if search_filters[:date_to]
      @blogs = @blogs.where(created_at: ..search_filters[:date_to])
    end

    respond_with @blogs
  end

  # GET /blogs/1
  def show
    @blog = Blog.find_by_id(params[:id])

    fresh_when(@blog)
    return unless stale?(@blog)

    respond_with @blog, status: :not_found and return unless @blog

    respond_with @blog
  end

  private

  def search_filters
    return @search_filters if defined?(@search_filters)

    @search_filters = begin
                value = JSON.parse(params[:filters], symbolize_names: true)
                value.is_a?(Hash) ? value : {}
              rescue TypeError, JSON::ParserError
                {}
              end
    @search_filters.each do |key, value|
      next unless %i[date_from date_to].include?(key)

      @search_filters[key] = begin
                       value = Time.parse(value).utc
                       value = value.beginning_of_day if key == :date_from
                       value = value.end_of_day if key == :date_to
                       value
                     rescue ArgumentError
                     end
    end
    @search_filters
  end

  def save_uploaded_file(field)
    return if field.nil?

    file = File.join('public/uploads', field.original_filename)
    FileUtils.cp field.tempfile.path, file
    field.original_filename
  end
end
