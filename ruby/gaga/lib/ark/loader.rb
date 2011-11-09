class Ark::Loader

  def self.load_all
    loaded_schemas = []
    true_grit = Ark::DB.send :git
    schemas = true_grit.status.map {|s| s.path if s.path =~ %r"^_schema/"}.compact
    schemas.each do |file|
      schema = file.split("/")[1]
      self.load(schema)
      loaded_schemas << schema
    end
    loaded_schemas
  end

  def self.load(name)
    begin
      schema_def = Ark::DB["_schema/#{name}"]
      create_class(schema_def)
    rescue Exception => e
      puts e.message
    end
  end

  # This adds a schema to the repo
  def self.add(schema_def)
    begin
      parsed_schema = JSON.parse(schema_def)
      Ark::DB.set("_schema/#{parsed_schema['id']}", schema_def)
    rescue Exception => e
      puts e.message
    end
  end

  def self.update(name, schema_def)
    Ark::DB["_schema/#{name}"] = schema_def
  end

  private
  def self.create_class(schema_def)
    schema = JSON.parse(schema_def)
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
