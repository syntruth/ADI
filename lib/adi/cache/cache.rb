module ADI
  # Define a simple, timed cache to store AD entries.
  class Cache
    attr_reader :options

    CacheEntry = Struct.new :time, :value

    # Valid Options are:
    #   - timeout: how long, in seconds, before and entry in invalid and
    #     removed.
    #
    #   - check_interval: how often, in seconds, that the cache will check for
    #     invalid entries and remove them. This is actually only checked when a
    #     key is checked for invalidity.
    def self.default_options
      {
        timeout:        300,
        check_interval: 900
      }
    end

    def initialize(options = {})
      @options = self.class.default_options.update(options)
      @store   = {}
    end

    def []=(key, value)
      set key, value
    end

    # Sets a value on the cache store.
    def set(key, value)
      @store[key] = CacheEntry.new Time.now.to_i, value
    end

    def [](key, &block)
      get key, &block
    end

    def get(key, &block)
      return remove(key) if invalidate? key

      value = @store[key]

      if block_given?
        block.call @store[key]

        return
      end

      value
    end

    def remove(key)
      @store.delete key

      nil
    end

    def clear!
      @store = {}
    end

    def invalidate?(key)
      check_for_invalids!

      entry = @store.fetch key, nil

      return false unless entry

      Time.now.to_i - entry.time > options[:timeout]
    end

    def check_for_invalids!
      now = Time.now.to_i

      @last_check ||= now

      check = now - @last_check

      return unless check > options[:check_interval]

      @store.delete_if { |_k, entry| timed_out? entry.time }

      @last_check = now
    end

    def timed_out?(time)
      Time.now.to_i - time > options[:timeout]
    end
  end
end
