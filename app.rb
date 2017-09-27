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
  erb :post_form
end

post '/approval' do
  data = JSON.parse(params["payload"])
  tweet = Nana.find_by(id: data["actions"].first["value"].to_i)
  if data["actions"].first["name"] == "ok"

    if tweet
      Hoge.twitter_auth.update (tweet.comment), { media_ids: tweet.media_ids }
      tweet.sent!
      json({text: "ツイートしました！"})

    else
      json({text: "データが見つかりませんでした"})
    end
  else
    tweet.sent!
    json({text: "キャンセルしました"})
  end
end

private

def sent_verification 
  nanas = Nana.where(status: "unsent")
  @payload = Hash.new
  uri = URI.parse(ENV.fetch("SLACK_URL"))
  https = Net::HTTP.new(uri.host, uri.port)

  https.use_ssl = true # HTTPSでよろしく
  req = Net::HTTP::Post.new(uri.request_uri)

  req["Content-Type"] = "application/json" # httpリクエストヘッダの追加

  if nanas.exists?
    nanas.each do |nana|
      color = ["#FF0000", "#00FF00", "#0000FF", "#FFFF00", "#FF00FF"].sample
      @payload = {
        "text": "[参加団体の宣伝]\n\n" + nana.comment ,

        "attachments": [
          {
            "color": color,
            "attachment_type": "default",
            "fields": [
              {
                "title": "現在の承認待ち数",
                "value": Nana.where(status: "verification").count,
                "short": true
              }
            ],
          }
        ]
      }
      nana.files.each_with_index do |v,i|
        @payload[:attachments][i] ||= {}
        @payload[:attachments][i].merge!({text: "#{i} image", image_url: v.medium.url, color: color})
      end
      @payload[:attachments].last.merge!({
        "fallback": "fallback string",
        "callback_id": "callback_id value",
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
      })
      nana.verification!
    end
  else
    @payload = {"text": "承認待ちはありません"}
  end
  req.body = @payload.to_json
  res = https.request(req)
  pp @payload
end
