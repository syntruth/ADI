# This API is to enable a more object oriented query DSL.
module ADI
  # This models a Query, that can be programatically chained before
  # doing an actual find in Active Directory.
  class Query
    attr_reader :type
    attr_reader :specifier
    attr_reader :base
    attr_reader :filters
    attr_reader :attributes

    def initialize(type)
      @type       = type
      @specifier  = :first
      @base       = init_base
      @filters    = nil
      @attributes = nil
    end

    def init_base
      hash = ADI.settings.fetch :server, {}

      hash.fetch :base, nil
    end

    ### API Start
    def call(&block)
      return call_first(&block) if specifier == :first
      return call_all(&block)   if specifier == :all
    end

    def in(base)
      unless base.is_a?(String) && !base.empty?
        raise ArgumentError, 'in argument needs to be a non-empty DC string!'
      end

      @options.update(base: base)

      self
    end

    def for(specifier)
      unless %i[all first].include?(specifier)
        raise ArgumentError, 'for argument needs to be either :all or :first!'
      end

      @specifier = specifier

      self
    end

    def first
      self.for :first
    end

    def all
      self.for :all
    end

    def where(filters)
      unless filters.is_a? Hash
        raise ArgumentError, 'where argument needs to be a Hash!'
      end

      @filters = filters

      self
    end

    def includes(*attributes)
      unless attributes.is_a?(Array) || attributes.empty?
        raise ArgumentError, '#includes needs 1 or more attributes'
      end

      @attributes = compile_attributes attributes

      self
    end

    def only(*attributes)
      unless attributes.is_a?(Array) || attributes.empty?
        raise ArgumentError, '#only needs 1 or more attributes'
      end

      @attributes = attributes

      self
    end
    ### API End

    def compile_attributes(attributes = [])
      # Get our default attributes for our type
      da = type.default_attributes || []

      # Get any attributes for this type from the config
      ca = config_attributes

      # Get any per-call attributes
      pa = attributes.is_a?(Array) ? attributes : []

      # OR each of the arrays together to get unique entries.
      da | ca | pa
    end

    # These are attributes options that are loaded from the config file, which
    # can have and: attributes parameter that should be a hash, with each key
    # being a Type with a list of string attributes to include in the LDAP
    # search. For example:
    #
    #  {
    #    ...,
    #    attributes: {
    #      user: [employeeid, department, title],
    #
    #      group: [...]
    #    }
    #  }
    #
    # If these do not exist, then each type's `default_attributes` class method
    # should return an array of keys, and if this array is empty, then all
    # attributes for the entry will be returned.
    def config_attributes
      attrs = ADI.attributes_settings_for type.class_name.downcase.to_sym

      attrs.is_a?(Array) ? attrs : []
    end

    def call_first(&block)
      results = ADI::Finder.first type, base, filters, attributes

      return results unless block_given?

      block.call(results)

      nil
    end

    def call_all(&block)
      results = ADI::Finder.all type, base, filters, attributes

      return results unless block_given?

      block.call(results)

      nil
    end

    def to_s
      format '%s [%s] filters: %s attributes: %s (%s)',
             type,
             specifier,
             obj_size(filters),
             obj_size(attributes),
             base
    end

    def inspect
      "<#{self.class.name} #{self}>"
    end

    private

    def obj_size(obj)
      obj.nil? ? 0 : obj.size
    end
  end
end
