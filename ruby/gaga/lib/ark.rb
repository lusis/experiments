require 'json'
require 'gaga'

module Ark
  DB = Gaga.new(:repo => ".data")
end

require File.join(File.dirname(__FILE__), 'ark', 'base')
require File.join(File.dirname(__FILE__), 'ark','loader')
