require 'rubygems'
require 'bundler'

Bundler.require

#set :environment, :production
disable :run

require 'trackifo'
run Trackifo::Application
