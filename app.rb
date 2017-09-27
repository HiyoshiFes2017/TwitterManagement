require 'bundler/setup'
Bundler.require
require "sinatra"
require "sinatra/base"
require "sinatra/reloader"
require "pry" if development?
require "json"
require 'net/http'
require 'uri'
require "./models"

not_found do
  {error: 404}.to_json
end

get '/' do
  erb :post_form
end

get '/send_to_slack' do
  sent_verification
  json({status: 200} )
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
  binding.pry
  erb :post_form
end

post '/approval' do
  data = JSON.parse(params["payload"])
  tweet = Nana.find_by(id: data["actions"].first["value"].to_i)
  if data["actions"].first["name"] == "ok"

    if tweet
      Hoge.twitter_auth.update (tweet.comment), { media_ids: tweet.media_ids }
      tweet.sent!
      json({text: "Successfully Tweeted!"})

    else
      json({text: "Error! select id is not found!"})
    end
  else
    tweet.sent!
    json({text: "Successfully Canceled!"})
  end
end

private

def sent_verification 
  Nana.where(status: "unsent").each do |nana|
    uri = URI.parse(ENV.fetch("SLACK_URL"))
    https = Net::HTTP.new(uri.host, uri.port)

    https.use_ssl = true # HTTPSでよろしく
    req = Net::HTTP::Post.new(uri.request_uri)

    req["Content-Type"] = "application/json" # httpリクエストヘッダの追加
    payload = {
      "text": nana.comment,
      "attachments": [
        {
          "fallback": "fallback string",
          "callback_id": "callback_id value",
          "color": "#FF0000",
          "attachment_type": "default",
          # "image_url": nana.file.medium.url,
          "actions": [
            {
              "name": "ok",
              "text": "承認",
              "type": "button",
              "style":"default",
              "value": nana.id
            },
            {
              "name": "no",
              "text": "拒否",
              "type": "button",
              "style":"danger",
              "value": nana.id
            }
          ]
        }
      ]
    }
    nana.files.each_with_index do |v,i|
      payload[:attachments][i] ||= {}
      payload[:attachments][i].merge!({text: "#{i} image", image_url: v.medium.url, color: "danger"})
    end
    pp payload
    req.body = payload.to_json
    res = https.request(req)
    nana.verification!
  end
end
