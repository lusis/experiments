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
