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
  mount_uploader :file, ImageUploader
  validates :comment, :file, presence: true
end

