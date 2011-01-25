require 'rubygems'
require 'bundler'

Bundler.require

#set :environment, :production
disable :run

configure :development do |config|
  require "sinatra/reloader"
  config.also_reload "lib/*.rb"
end

require 'trackifo'
run Trackifo::Application
