#!/usr/bin/env ruby

require 'erb'
require 'sinatra/base'
require 'yaml'

CONFIG_FILE = File.join(File.dirname(__FILE__), 'config.yml')

class WebServer < Sinatra::Base
  configure do
    set :port, 80
    set :public, File.join(File.dirname(__FILE__), 'public')
    set :views, File.join(File.dirname(__FILE__), 'views')
  end

  get // do
    erb :index
  end
end

if Process.euid != 0
  puts "error: this script must be run as root"
  exit 1
end

config = {}
if File.exist?(CONFIG_FILE)
  File.open(CONFIG_FILE, 'r') do |f|
    config = YAML.load(f)
  end
else
  File.open(File.join(File.dirname(__FILE__), 'config.yml.dist'), 'r') do |f|
    config = YAML.load(f)
  end
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
