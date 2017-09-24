require 'bundler/setup'
Bundler.require
require './carrier_wave'
require 'carrierwave/orm/activerecord'
require 'carrierwave/processing/rmagick'

config  = YAML.load_file( './database.yml' )
ActiveRecord::Base.configurations = config
ActiveRecord::Base.establish_connection(config["development"])

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
  mount_uploader :file, ImageUploader
  validates :comment, :file, presence: true
end

