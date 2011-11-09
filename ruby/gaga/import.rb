#!/usr/bin/env ruby
$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), "lib")))

require 'ark'
schemas = Dir["schema_defs/*"]
schemas.each do |file|
  Ark::Loader.add(File.open(file, "r") {|f| f.read})
  puts "Imported #{file}"
end

puts "Activating schemas"
Ark::Loader.load_all

puts "Creating hosts"
10.times do |x|
  h = Host.new
  h.name = "host#{x}.domain.com"
  h.status = "up"
  h.save
  puts "host#{x} created"
end
