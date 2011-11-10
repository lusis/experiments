$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), "lib")))

require 'sinatra/base'
require 'ark'
require 'json'

Ark::Loader.load_all

class Web < Sinatra::Base
  configure do
    set :show_exceptions, false
    set :raise_errors, false
    set :run, false
    set :logging, true
  end

  put '/_schema/?' do
    begin
      data = JSON.parse(request.body.read)
      Ark::Loader.add(data)
      Ark::Loader.load(data['id'])
      '{"message":"schema added"}'
    rescue Exception => e
      e.message
    end
  end

  get '/:model/?' do |model|
    begin
      klass = Kernel.const_get(model.capitalize)
      count = 0
      matches = klass.all.inject({}) {|hash, match| hash[count] = match.to_hash; count +=1; hash }
      halt if matches.empty?
      matches.to_json
    rescue NameError
      halt
    end
  end

  get '/:model/:attribute/:val/?' do |model, attribute, val|
    begin
      klass = Kernel.const_get(model.capitalize)
      count = 0
      matches = klass.find_by_attr(attribute, val).inject({}) do |hash, match|
        hash[count] = match.to_hash
        count += 1
        hash
      end
      halt if matches.empty? # fix this
      matches.to_json
      
    rescue NameError
      halt 
    end
  end
end

Web.run!
