require 'bundler/setup'
Bundler.require
require './carrier_wave'
require 'carrierwave/orm/activerecord'
require 'carrierwave/processing/rmagick'

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
end

