class BlogsController < ApplicationController
  wrap_parameters Blog
  respond_to :json

  # POST /blogs
  def create
    @blog = Blog.create(params[:blog])
    respond_with @blog
  end

  # GET /blogs
  def index
    @blogs = Blog.all
    respond_with @blogs
  end

  # GET /blogs/1
  def show
    @blog = Blog.find(params[:id])
    respond_with @blog
  end
end
