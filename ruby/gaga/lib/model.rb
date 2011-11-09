require 'json'
require 'gaga'

module Ark
  DB = Gaga.new(:repo => ".data")
end

class Ark::Base
  attr_accessor :version, :schema, :errors

  def initialize
    @db = Ark::DB
    @version ||= 1
    @schema = self.class::SCHEMA
  end

  def valid?
    @errors = []
    self.validate
  end

  def save
    self.valid? ? @db.set("#{@schema["id"]}/#{name}", self) : self.errors
  end

  def [](key)
    @db.get("#{@schema["id"]}/#{key}")
  end

  def self.all
    # Gaga doesn't expose anything like this
    # I totally shouldn't do this
    # This is bad
    # ..really bad
    # Like, this is the shit that people criticize folks for doing
    # I should probably just manage an index myself
    true_grit = Ark::DB.send :git
    true_grit.status.map {|file| f=file.path.split("/"); f[1] if f[0] == self.const_get("SCHEMA")['id']}.compact
  end

  protected
  def validate
    # this needs to validate type as well as other validations
    valid = true
    @schema["attributes"].each do |attr, validation|
      case validation.class.to_s
      when "String"
        if instance_eval("@#{attr}").class.to_s != validation.capitalize
          @errors << [attr.to_sym, :invalid_format]
          valid = false
        end
      when "Array"
        unless validation.include?(instance_eval("@#{attr}"))
          @errors << [attr.to_sym, :invalid_option]
          valid = false
        end
      end
    end
    return valid
  end
end

class Ark::Loader

  # This pulls all existing schemas from the repo and creates new classes
  def self.load_all
    loaded_schemas = []
    true_grit = Ark::DB.send :git
    schemas = true_grit.status.map {|s| s.path if s.path =~ %r"^_schema/"}.compact
    schemas.each do |file|
      schema = Ark::DB[file]
      self.load(schema)
      loaded_schemas << file.split("/")[1]
    end
    loaded_schemas
  end

  # this loads an individual schema from the repo - poorly named
  # should probably just pull a schema by name as opposed to from a definition
  def self.load(schema)
    begin
      jschema = JSON.parse(schema)
      #@db = Ark::DB.get("_schema/#{jschema['id']}") || Ark::DB["_schema/#{jschema['id']}"] = schema
      create_class(jschema)
    rescue Exception => e
      puts e.message
    end
  end

  # This adds a schema to the repo
  def self.add_schema(schema)
    begin
      jschema = JSON.parse(schema)
      Ark::DB["_schema/#{jschema['id']}"] = schema
    rescue Exception => e
      puts e.message
    end
  end

  private
  def self.create_class(schema)
    klass_name = schema['id'].capitalize
    klass = Object.const_set(klass_name, Class.new(Ark::Base))
    klass.class_eval do
      attr_accessor *schema['attributes'].keys
    end
    klass.const_set('SCHEMA', schema)
    Kernel.const_set klass_name, klass
  end

  def self.model_to_object(schema)
    klass_name = schema['id'].capitalize
    klass = Object.const_set(klass_name, Class.new(Ark::Base))
    klass.class_eval do
      attr_accessor *schema['attributes'].keys
    end
    s = klass.new(schema)
    s
  end
end

@json =<<EOJ
{"id":"host",
  "attributes":{
    "name":"string",
    "status":[
      "up",
      "down",
      "pending_up",
      "pending_down"
    ]
  },
  "validations":{
    "required":["name"]
  }
}
EOJ
