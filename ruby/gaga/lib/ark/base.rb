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
    self.valid? ? @db.set("#{@schema["id"]}/#{name}", self) : (return false)
  end

  def [](key)
    @db.get("#{@schema["id"]}/#{key}")
  end

  def to_hash
    h = @schema['attributes'].keys.inject({}) do |hash, key|
      hash[key] = instance_eval("@#{key}")
      hash
    end
    h
  end

  def self.all
    # Gaga doesn't expose anything like this
    # I totally shouldn't do this
    # This is bad
    # ..really bad
    # Like, this is the shit that people criticize folks for doing
    # I should probably just manage an index myself
    prefix = const_get("SCHEMA")['id']
    true_grit = Ark::DB.send :git
    all = true_grit.status.inject([]) {|arr, file| arr << Ark::DB[file.path] if file.path.split("/")[0] == "#{prefix}"; arr}
    all
  end

  def self.find(key)
    Ark::DB.get("#{self.const_get("SCHEMA")['id']}/#{key}")
  end

  def self.find_by_attr(attr, value)
    self.all.find_all {|i| i.send(attr.to_sym) == value}
  end

  protected
  def validate
    @errors = []
    # this needs to validate type as well as other validations
    uniques = @schema['validations']['required'] || []
    required = @schema['validations']['unique'] || []

    # determine any requirements first
    @schema["validations"].each do |validation, attrs|
      case validation
      when "required"
        attrs.map {|a| @errors << [a.to_sym, :required] if instance_eval("@#{a}").nil? }
      when "unique"
        attrs.map do |a|
          self.class.find_by_attr(a, self.send(a.to_sym)).each do |c|
            @errors << [a.to_sym, :not_unique] unless c.nil?
          end
        end
      end
    end
    @schema["attributes"].each do |attr, validation|
      if required.include?(attr)
        case validation.class.to_s
        when "String"
          if instance_eval("@#{attr}").class.to_s != validation.capitalize
            @errors << [attr.to_sym, :invalid_format]
          end
        when "Array"
          unless validation.include?(instance_eval("@#{attr}"))
            @errors << [attr.to_sym, :invalid_option]
          end
        end
      end
    end
    @errors.size > 0 ? false : true
  end
end
