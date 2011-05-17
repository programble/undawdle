#!/usr/bin/env ruby

require 'erb'
require 'sinatra/base'
require 'yaml'

config_file = File.join(File.dirname(__FILE__), 'config.yml')
config_file = File.join(File.dirname(__FILE__), 'config.yml.dist') unless File.exist?(config_file)

class WebServer < Sinatra::Base
  configure do
    set :port, 80
    set :public, File.join(File.dirname(__FILE__), 'public')
    set :views, File.join(File.dirname(__FILE__), 'views')
  end

  get %r{} do
    erb :index
  end
end

if Process.euid != 0
  puts "error: this script must be run as root"
  exit 1
end

config = {}
File.open(config_file, 'r') do |file|
  config = YAML.load(file)
end

original_hosts = File.open(config['hosts-file'], 'r').read

File.open(config['hosts-file'], 'a') do |file|
  file.puts '#---undawdle---'
  config['sites'].each do |site|
    file.puts "127.0.0.1 #{site}"
    file.puts "127.0.0.1 www.#{site}"
  end
end

system(config['restart-networking'])

WebServer.run!

File.open(config['hosts-file'], 'w') do |file|
  file << original_hosts
end

system(config['restart-networking'])
