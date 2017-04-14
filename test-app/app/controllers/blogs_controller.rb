class BlogsController < ApplicationController
  wrap_parameters Blog
  respond_to :json

  # POST /blogs
  def create
    thumbnail = save_uploaded_file(params[:blog][:thumbnail])
    @blog = Blog.create(params.require(:blog).permit(:title, :content).merge(:thumbnail => thumbnail))
    respond_with @blog
  end

  # Put /blogs/1
  def upload
    @blog = Blog.find_by_id(params[:id])
    return head :not_found if @blog.nil?
    @blog.thumbnail = save_uploaded_file params[:file]
    head @blog.save ? :ok : :unprocsessible_entity
  end

  # GET /blogs
  def index
    @blogs = Blog.all
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

  def save_uploaded_file(field)
    return if field.nil?
    require 'fileutils'
    file = File.join('tmp', field.original_filename)
    FileUtils.cp field.tempfile.path, file
    field.original_filename
  end
end
