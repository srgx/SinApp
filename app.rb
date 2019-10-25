require 'bundler/setup'
require 'sinatra'
require 'data_mapper'
require 'sinatra/flash'
require 'will_paginate'
require 'will_paginate/data_mapper'
require 'faker'
enable :sessions

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/blog.db")

class Post
    include DataMapper::Resource
    property :id, Serial
    property :title, String, :required => true
    property :body, Text, :required => true
    property :votes_up,    Integer
    property :votes_down,  Integer
    property :created_at, DateTime

    has n, :comments, constraint: :destroy
end

class Comment
  include DataMapper::Resource

  property :id,         Serial
  property :posted_by,  String, :required => true
  property :body,       Text, :required => true

  belongs_to :post
end


DataMapper.finalize
DataMapper.auto_upgrade!


# SEED DATABASE
if (Post.count < 5)
  10.times do
    Post.create(
      title: Faker::Coffee.blend_name,
      body: Faker::Coffee.origin,
      votes_up: 0,
      votes_down: 0,
      created_at: Time.now
    )
  end
end



get '/' do
  erb :index
end

# SHOW ALL POSTS
get '/posts' do
  @posts = Post.paginate(page: params[:page], per_page: 3)
  erb :posts
end

# NEW POST FORM
get '/posts/new' do
  erb :posts_new
end

# SHOW POST
get '/posts/:id' do
  @post = Post.get(params[:id])
  erb :posts_show
end

# EDIT POST FORM
get '/posts/:id/edit' do
  @post = Post.get(params[:id])
  erb :posts_edit
end

# CREATE POST
post '/posts' do
  post = Post.new(
    title: params[:title],
    body: params[:body],
    votes_up: 0,
    votes_down: 0,
    created_at: Time.now
  )
  if post.save
    flash[:notice] = "Post created"
    redirect '/posts'
  else
    flash[:error] = "Error"
    redirect back
  end
end


# UPDATE POST
put '/posts/:id' do
  post = Post.get(params[:id])

  if post.update(title:params[:title],body:params[:body])
    flash[:notice] = "Post updated"
    redirect '/posts'
  else
    flash[:error] = "Error"
    redirect back
  end
end


# DESTROY POST
delete '/posts/:id' do
  post = Post.get(params[:id])
  post.destroy
  flash[:notice] = "Post destroyed"
  redirect '/posts'
end


# CREATE COMMENT
post '/posts/:id/comments' do
  post = Post.get(params[:id])
  comment = post.comments.new(posted_by:params[:posted_by],body:params[:body])

  if comment.save
    flash[:notice] = "Comment created"
  else
    flash[:error] = "Error"
  end

  redirect back
end

# DESTROY COMMENT
delete '/posts/:post_id/comments/:comment_id' do
  comment = Comment.get(params[:comment_id])
  comment.destroy
  flash[:notice] = "Comment destroyed"
  redirect back
end

put '/upvote_post/:post_id' do
  post = Post.get(params[:post_id])
  votes = post.votes_up
  post.update(votes_up:votes+1)
  flash[:notice] = "Upvoted"
  redirect back
end

put '/downvote_post/:post_id' do
  post = Post.get(params[:post_id])
  votes = post.votes_down
  post.update(votes_down:votes+1)
  flash[:notice] = "Downvoted"
  redirect back
end

get '/statistics' do
  @number_of_posts = Post.count
  @number_of_comments = Comment.count
  erb :statistics
end
