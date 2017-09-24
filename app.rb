require 'bundler/setup'
Bundler.require
require "sinatra"
require "sinatra/base"
require "sinatra/reloader"
require "pry" if development?
require "json"

require "./models"

not_found do
  {error: 404}.to_json
end

get '/' do
  erb :post_form
end

post '/register' do
  nana = Nana.new(file: params[:image], comment: params[:comment])
  if nana.save
    session[:responce] = {code: 200, messages: "成功しました"}
  else
    session[:responce] = {code: 400, messages: nana.errors.full_messages[0]}
  end
  binding.pry
  erb :post_form
end
