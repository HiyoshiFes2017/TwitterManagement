require 'bundler/setup'
Bundler.require
require './carrier_wave'
require 'carrierwave/orm/activerecord'
require 'carrierwave/processing/rmagick'
require 'net/http'
require 'uri'
require 'json'

config  = YAML.load_file( './database.yml' )

ActiveRecord::Base.configurations = config
if development?
  ActiveRecord::Base.establish_connection(config["development"])
else
  ActiveRecord::Base.establish_connection(config["production"])
end

Time.zone = "Tokyo"
ActiveRecord::Base.default_timezone = :local

after do
  ActiveRecord::Base.connection.close
end

class ImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::RMagick
  storage :fog
  version :medium do
    process :resize_to_fit => [1280, 720]
  end
  version :large do
    process :resize_to_fit => [1920, 1080]
  end
end

class Nana < ActiveRecord::Base
  mount_uploaders :files, ImageUploader
  validates :comment, presence: true
  validates :comment, length: { maximum: 124 }
  enum status: {unsent: 0, verification: 1, sent: 2}
end


class Hoge
  def self.twitter_auth
    @rest = Twitter::REST::Client.new(
      {
        consumer_key: ENV.fetch("CONSUMER_KEY"),
        consumer_secret: ENV.fetch("CONSUMER_SECRET"),
        access_token: ENV.fetch("ACCESS_TOKEN"),
        access_token_secret: ENV.fetch("ACCESS_TOKEN_SECRET")
      }
    )
  end

  def self.sent_verification
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
              "name":  "ok",
              "text":  "承認",
              "type":  "button",
              "style": "success",
              "value":  nana.id
            },
            {
              "name":  "no",
              "text":  "拒否",
              "type":  "button",
              "style": "danger",
              "value":  nana.id
            }
          ]
        })
        nana.verification!
      end
    end
    req.body = @payload.to_json
    res = https.request(req)
    return res.msg
  end
end

