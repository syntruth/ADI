# This API is to enable a more object oriented query DSL.
module ADI
  # This models a Query, that can be programatically chained before doing an
  # actual find in Active Directory.
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
      unless attributes.is_a?(Array) || attribute.empty?
        raise ArgumentError, 'attributes argument needs to be an Array!'
      end

      @attributes = attributes

      self
    end
    ### API End

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
      fsz  = obj_size @filters
      asz  = obj_size @attributes
      str  = "#{@type} :#{@specifier} filters: #{fsz} attributes: #{asz}"
      bstr = @options[:in]

      str = "#{str} #{bstr}" if bstr

      str
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
