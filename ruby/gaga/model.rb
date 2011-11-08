require 'json'

class BaseModel
  # define how to handle validations here
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
    s = klass.new
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

