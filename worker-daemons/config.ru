require 'rubygems'
require 'sinatra'
require File.expand_path '../worker.rb', __FILE__

run Sinatra::Application
