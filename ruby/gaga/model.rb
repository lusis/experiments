require 'json'
require 'gaga'

class BaseModel
  attr_accessor :version, :schema, :errors

  def initialize(schema)
    @db = Gaga.new(:repo => ".data")
    @schema = schema
    @version ||= 1
  end

  def valid?
    @errors = []
    self.validate
  end

  def save
    @db.set("#{@schema["id"]}_#{name}", self)
  end

  def [](key)
    @db.get("#{@schema["id"]}_#{key}")
  end

  def all
    @db.keys
  end

  protected
  def validate
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

class Model

  def self.load(schema)
    jschema = JSON.parse(schema)
    model_to_object(jschema)
  end

  private
  def self.model_to_object(schema)
    klass_name = schema['id'].capitalize
    klass = Object.const_set(klass_name, Class.new(BaseModel))
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
  }
}
EOJ
