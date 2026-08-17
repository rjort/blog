class PostsController < ApplicationController
  def index
    @posts_by_year = Post.all_by_year
  end

  def show
    @post = Post.find_by_slug(params[:slug])
    if @post.nil?
      render file: Rails.root.join("public", "404.html"), status: :not_found, layout: false
    end
  end
end
