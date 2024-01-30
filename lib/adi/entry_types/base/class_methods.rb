module ADI
  # Class Methods for the Base class
  class Base
    # This setups up the Base entry type, from which all other Types are
    # subclasses of. The two settings options, are are passed in from
    # `ADI.setup` are `:cache` and `:attributes`, which are hashes
    # defined in the config settings given to ADI.setup.
    def self.setup(settings)
      self.cache_settings      = settings.fetch :cache,      {}
      self.attributes_settings = settings.fetch :attributes, []
    end

    # Pull the class we're in.
    #
    # This isn't quite right, as extending the object does funny things
    # to how we lookup objects
    def self.class_name
      @class_name ||= name.include?('::') ? name.split('::').last : name
    end

    # Initializes a Query object for programmatic building of the query.
    def self.query
      ADI::Query.new self
    end

    # Required Attributes for creating an entry. This should be
    # overridden by subclasses.
    def self.required_attributes
      {}
    end

    # These are the minimum attributes to be pulled with this type, and
    # will be modified by any :attributes key in the `#find` options.
    #
    # Base is an empty array, and thus will pull everything.
    def self.default_attributes
      []
    end

    def self.filter # :nodoc:
      NIL_FILTER
    end

    # Create a new entry in the Active Record store.
    #
    # dn is the Distinguished Name for the new entry. This must be a
    # unique identifier, and can be passed as either a Container or a
    # plain string.
    #
    # attributes is a symbol-keyed hash of attribute_name: value pairs.
    def self.create(dgn, attributes)
      return nil if dgn.nil? || attributes.nil?

      attributes.merge! required_attributes

      dgn = dgn.to_s

      if ADI.ldap.add(dn: dgn, attributes: attributes)
        return find :first, dn: dgn
      end

      nil
    rescue StandardError
      nil
    end

    # Performs a search on the Active Directory store.
    def self.find(specifier, params = {}, attributes = [])
      query.for(specifier).where(params).includes(attributes).call
    end

    # Syntantic Sugar for now.
    def find_first(params = {}, attributes = [])
      find :first, params, attributes
    end

    def find_all(params = {}, attributes = [])
      find :all, params, attributes
    end

    # Grabs the field type depending on the class it is called from
    #
    # Takes the field name as a parameter
    def self.get_field_type(name)
      unless name.is_a?(String) || name.is_a?(Symbol)
        raise ArgumentError, "Invalid field name: #{name}"
      end

      klass = class_name.to_sym
      name  = name.to_s.downcase.to_sym

      type = ::ADI.special_fields[klass][name]

      type ? type.to_s : nil
    end

    def self.decode_field(name, value) # :nodoc:
      type = get_field_type name

      if !type.nil? && ::ADI::FieldType.const_defined?(type)
        return ::ADI::FieldType.const_get(type).decode(value)
      end

      value
    end

    def self.encode_field(name, value) # :nodoc:
      type = get_field_type name

      if !type.nil? && ::ADI::FieldType.const_defined?(type)
        return ::ADI::FieldType.const_get(type).encode(value)
      end

      value
    end
  end
end
