module ADI
  # Class Methods for the Base class
  class Base
    # Check to see if result caching is enabled
    def self.caching?
      cache ? true : false
    end

    # Clears the cache
    def self.clear_cache
      cache.clear! if cache
    end

    # Enable caching for queries against the DN only
    #
    # This is to prevent membership lookups from hitting the AD unnecessarilly
    def self.enable_cache
      return if cache

      opts = cache_settings || {}

      self.cache = ADI::Cache.new opts
    end

    # Disable caching
    def self.disable_cache
      cache.clear! if cache

      self.cache = nil
    end

    # Adds an entry to the cache, however, we do so only if we are caching and
    # the object is not an instance of the Base type.
    def self.add_to_cache(entry)
      cache[entry.dn] = entry if caching? && !entry.class.class_name != 'Base'

      # We return the entry regardless
      entry
    end

    # Searches the cache and returns the result
    #
    # Returns false on failure, nil on wrong object type
    def self.find_cached_results(filters)
      return false unless caching?

      # Check to see if we're only looking for :distinguishedname
      return false unless filters.is_a?(Hash) &&
                          filters.keys == [:distinguishedname]

      # Find keys we're looking up
      dns = filters[:distinguishedname]

      return find_cached_results_array(dns) if dns.is_a?(Array)

      result = cache[dns]

      return false unless result && result.is_a?(self)

      result
    end

    def self.find_cached_results_array(dns = [])
      dns.filter_map do |dn|
        entry = cache[dn]

        # Only return entries of the type that we're looking for.
        return false unless entry && entry.is_a(self)

        entry
      end
    end
  end
end
