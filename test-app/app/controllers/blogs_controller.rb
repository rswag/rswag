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

  # GET /blogs
  def index
    @blogs = Blog.all
    @blogs = @blogs.where(status: params[:status]) if params[:status].present?

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
    file = File.join('public/uploads', field.original_filename)
    FileUtils.cp field.tempfile.path, file
    field.original_filename
  end
end
