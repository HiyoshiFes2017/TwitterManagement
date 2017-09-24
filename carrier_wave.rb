require 'carrierwave/orm/activerecord'

CarrierWave.configure do |config|
  config.fog_credentials = {
    # Configuration for Amazon S3
    :provider              => 'AWS',
    :aws_access_key_id     => ENV.fetch('ACCESS_KEY'),
    :aws_secret_access_key => ENV.fetch('SECRET_KEY'),
    :region                => 'ap-northeast-1'
  }

  config.cache_dir = "tmp/uploads"
  config.fog_directory  = 'hiyoshi-photos'
  config.fog_public     = false
  config.fog_attributes = { 'Cache-Control' => "max-age=#{365.day.to_i}" }
  config.storage = :fog
end

