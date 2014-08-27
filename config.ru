require 'rubygems'
require 'bundler'

Bundler.require

require './app.rb'
require 'rack'

map "/go" do
  run Pinocchio
end