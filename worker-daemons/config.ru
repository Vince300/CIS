require 'rubygems'
require 'sinatra'
require File.expand_path '../worker.rb', __FILE__

warmup do |app|
    # dRuby must only listen on localhost
    DRb.start_service("druby://localhost:0")
end

run Sinatra::Application
