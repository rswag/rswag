class BlogsController < ApplicationController

  # POST /blogs
  def create
    @blog = Blog.create(params.require(:blog).permit(:title, :content))
    respond_with @blog
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
end
