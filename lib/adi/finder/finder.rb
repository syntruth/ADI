module ADI
  # This defines the Finder class, which is responsible for actually
  # talking to the LDAP/AD servers and pulling information.
  #
  # Finder utilizes the `ADI.ldap` connection, and does not do so on its
  # own. It's merely to encapsulate the find/search functionality.
  class Finder
    attr_reader :type
    attr_reader :base
    attr_reader :filters
    attr_reader :attributes

    def self.first(type, base, filters = {}, attributes = [])
      new(type, base, filters, attributes).first
    end

    def self.all(type, base, filters = {}, attributes = [])
      new(type, base, filters, attributes).all
    end

    def initialize(type, base, filters = {}, attributes = [])
      @type       = type
      @base       = base
      @filters    = make_filter_from_hash filters
      @attributes = attributes
    end

    def first
      perform :first
    end

    def all
      perform :all
    end

    # Performs a search on the Active Directory store.
    def perform(specifier = :first)
      cached = type.find_cached_results filters

      return cached if cached

      options = finalize_find_options base, filters, attributes

      return find_first(options) if specifier == :first
      return find_all(options)   if specifier == :all
    end

    def find_first(options)
      result = ldap_search options

      return nil if result.nil? || result.empty?

      entry = type.new result[0]

      type.add_to_cache entry
    end

    def find_all(options)
      objs = ldap_search(options) || []

      objs.map do |obj|
        entry = type.new obj

        type.add_to_cache entry
      end
    end

    def make_filter_from_hash(hash)
      return ADI::NIL_FILTER if hash.nil? || hash.empty?

      filter = nil

      hash.each do |key, value|
        if filter
          filter &= make_filter(key, value)

          next
        end

        filter = make_filter(key, value)
      end

      filter
    end

    def make_filter(key, value)
      # If the value is an Array, then join the values using an OR
      # condition
      if value.is_a? Array
        filter = nil

        value.each do |v|
          f = create_filter key, v

          # If filter is not nil, then OR the additional filter, else
          # set to the filter.
          filter = filter ? (filter |= f) : f
        end

        return filter
      end

      value.gsub!(/^\[|\]$/, '')

      create_filter key, value
    end

    # This creates a filter based on the Type's `encode_field` method.
    def create_filter(key, value)
      Net::LDAP::Filter.eq key, type.encode_field(key, value).to_s
    end

    def finalize_find_options(base, filters = {}, attributes = [])
      options = { base: base, filter: filters, attributes: attributes }

      return options if type.filter == NIL_FILTER

      options[:filter] = (options[:filter] & type.filter)

      options
    end

    # Does the actual LDAP search call to DRY things up. Returns nil if
    # there are no matches.
    def ldap_search(options)
      return unless ADI.connected?

      ADI.ldap.search options
    end
  end
end
