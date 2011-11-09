#!/usr/bin/env ruby
$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), "lib")))

require 'ark'

puts "Activating schemas"
Ark::Loader.load_all

puts Host.all
