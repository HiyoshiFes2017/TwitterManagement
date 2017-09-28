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
  # session["responce"] = nil
  erb :post_form
end

get '/send_to_slack' do
  if Hoge.sent_verification == "OK"
    json({status: 200})
  else 
    json({status: 500})
  end
end

post '/register' do
  nana, media_ids = Nana.new(comment: params[:comment]), Array.new
  nana.files = params[:images]
  if nana.save
    nana.files.each do |file|
      media_ids << Hoge.twitter_auth.upload(open(file.medium.url))
    end
    nana.media_ids = media_ids.join(',')
    session[:responce] = {code: 200, messages: "成功しました", images: nana.files} if nana.save
  else
    session[:responce] = {code: 400, messages: nana.errors.full_messages[0]}
  end
  erb :post_form
end

post '/approval' do
  data = JSON.parse(params["payload"])
  nana = Nana.find_by(id: data["actions"].first["value"].to_i)
  if data["actions"].first["name"] == "ok"

    if nana
      Hoge.twitter_auth.update (nana.comment), { media_ids: nana.media_ids }
      nana.sent!
      json({text: "ツイートしました！"})

    else
      json({text: "データが見つかりませんでした"})
    end
  else
    nana.sent!
    json({text: "キャンセルしました"})
  end
end

