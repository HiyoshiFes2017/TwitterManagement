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
  sent_verification
  erb :post_form
end

post '/register' do
  nana = Nana.new(file: params[:image], comment: params[:comment])
  if nana.save
    session[:responce] = {code: 200, messages: "成功しました"}
  else
    session[:responce] = {code: 400, messages: nana.errors.full_messages[0]}
  end
  erb :post_form
end

post '/approval' do
  data = JSON.parse(params["payload"])
  if data["actions"].first["name"] == "ok"
    @rest = Twitter::REST::Client.new(
      {
        consumer_key: ENV.fetch("CONSUMER_KEY"),
        consumer_secret: ENV.fetch("CONSUMER_SECRET"),
        access_token: ENV.fetch("ACCESS_TOKEN"),
        access_token_secret: ENV.fetch("ACCESS_TOKEN_SECRET")
      }

    )
    tweet = Nana.find_by(id: data["actions"].first["value"].to_i)
    # @rest.update("#{tweet.comment}\n#{tweet.file.medium.url}")
    open(tweet.file.medium.url) do |tmp|
      @rest.update_with_media(tweet.comment, tmp)
    end
    tweet.sent!
    pp data
  else
    tweet.sent!
  end
  data["original_message"]["text"] = "Succes Tweet!"
  json({payload: data})
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
          "image_url": nana.file.medium.url,
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
    }.to_json
    req.body = payload
    res = https.request(req)
    # nana.verification! if development?
  end
end
