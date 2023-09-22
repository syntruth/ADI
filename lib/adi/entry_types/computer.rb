module ADI
  # AD Entry for Computer
  class Computer < Base
    def self.filter # :nodoc:
      Net::LDAP::Filter.eq(:objectClass, 'computer')
    end

    def self.required_attributes # :nodoc:
      { objectClass: %w[top person organizationalPerson user computer] }
    end

    def self.default_attributes
      %w[dNSHostName name]
    end

    def hostname
      dNSHostName || name
    end
  end
end
