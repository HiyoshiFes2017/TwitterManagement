require 'bundler'
Bundler.require
require './carrier_wave'
require './app'

run Sinatra::Application
