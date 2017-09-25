# frozen_string_literal: true
source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

#server
gem "rake"
gem "sinatra"
gem "sinatra-contrib"
gem "sinatra-activerecord"

#image upload
gem 'carrierwave'
gem 'rmagick'
gem 'fog'

#time keeper
gem 'whenever' , :require => false

#twitter
gem 'twitter'

#database
gem 'pg', '~> 0.18'

group :development, :test do
  gem "pry"
  gem "pry-byebug"
end

