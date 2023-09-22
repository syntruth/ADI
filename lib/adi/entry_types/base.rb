module ADI
  # Base class for all Active Directory Entry Objects
  class Base
    # rubocop:disable Style/ClassVars
    @@cache_settings      = nil
    @@attributes_settings = nil
    @@attributes          = []
    @@ldap                = false
    @@ldap_connected      = false
    @@cache               = nil

    def self.cache_settings
      @@cache_settings
    end

    def self.cache_settings=(val)
      @@cache_settings = val
    end

    def self.attributes_settings
      @@attributes_settings
    end

    def self.attributes_settings=(val)
      return unless val.is_a? Array

      @@attributes_settings = val
    end

    def self.cache
      @@cache
    end

    def self.cache=(obj)
      @@cache = obj
    end
    # rubocop:enable Style/ClassVars
  end
end

require_relative './base/class_methods'
require_relative './base/instance_methods'
require_relative './base/cache'
