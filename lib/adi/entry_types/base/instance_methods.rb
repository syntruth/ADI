module ADI
  # Instance Methods for the Base class
  class Base
    # Checks for equality based on the ObjectGUID value.
    def ==(other)
      return false if other.nil?

      other[:objectguid] == get_attr(:objectguid)
    end

    # Whether or not the entry has local changes that have not yet been
    # replicated to the Active Directory server via a call to Base#save
    def changed?
      !@attributes.empty?
    end

    # Returns true if this entry does not yet exist in Active Directory.
    def new_record?
      @entry.nil?
    end

    # Refreshes the attributes for the entry with updated data from the
    # domain controller.
    def reload
      return false if new_record?

      filter = Net::LDAP::Filter.eq('distinguishedName', distinguishedName)
      @entry = self.class.ldap.search(filter: filter)[0]

      !@entry.nil?
    end

    # Updates a single attribute (name) with one or more values, by
    # immediately contacting the Active Directory server and initiating
    # the update remotely.
    #
    # Entries are always reloaded via Base.reload after calling this
    # method.
    def update_attribute(name, value)
      update_attributes(name.to_s => value)
    end

    # Updates multiple attributes, like ActiveRecord#update_attributes.
    # The updates are immediately sent to the server for processing, and
    # the entry is reloaded after the update (if all went well).
    def update_attributes(attributes_to_update)
      return true if attributes_to_update.empty?

      ops = create_update_attributes attributes_to_update

      self.class.ldap.modify(dn: distinguishedName, operations: ops) && reload
    end

    def create_update_attributes(attributes_to_update = [])
      ops = []

      attributes_to_update.each do |attr, values|
        op = create_update_attributes_op attr, values

        next unless op

        ops.push op
      end

      ops
    end

    def create_update_attributes_op(attr, value)
      return [:delete, attr, nil] if value.nil? || value.empty?

      current = entry_attribute attr

      return false unless current

      op = currenty.nil? ? :add : :replace

      [op, attr, value]
    end

    def entry_attribute(attribute)
      @entry[attribute]
    rescue NoMethodError
      nil
    end

    # Deletes the entry from the Active Directory store and returns true
    # if the operation was successfully.
    def destroy
      return false if new_record?

      return false unless self.class.ldap.delete(dn: distinguishedName)

      @entry      = nil
      @attributes = {}

      true
    end

    # Saves any pending changes to the entry by updating the remote
    # entry.
    def save
      return false unless update_attributes @attributes

      @attributes = {}

      true
    end

    # This method may one day provide the ability to move entries from
    # container to container. Currently, it does nothing, as we are
    # waiting on the Net::LDAP folks to either document the
    # Net::LDAP#modrdn method, or provide a similar method for
    # moving/renaming LDAP entries.
    def move(_new_rdn)
      false

      # return false if new_record?

      # settings = self.class.settings.dup

      # settings[:port]       = 636
      # settings[:encryption] = { method: :simple_tls }

      # ldap = Net::LDAP.newsettings

      # if ldap.rename olddn:             distinguishedName,
      #                newrdn:            new_rdn,
      #                delete_attributes: false

      #   return true
      # end

      # puts Base.error

      # false
    end

    # FIXME: Need to document the Base::new
    def initialize(attributes = {}) # :nodoc:
      if attributes.is_a? Net::LDAP::Entry
        @entry      = attributes
        @attributes = {}

        return
      end

      @entry      = nil
      @attributes = attributes
    end

    def valid_attribute?(name)
      @attributes.key?(name) || @entry.attribute_names.include?(name)
    end

    def get_attr(name)
      name = name.to_s.downcase

      if @attributes.key?(name.to_sym)
        return decode_field(name, @attributes[name.to_sym])
      end

      return unless @entry.attribute_names.include? name.to_sym

      value = get_attr_value @entry[name.to_sym]

      self.class.decode_field(name, value)
    end

    def get_attr_value(value)
      value = value.first if value.is_a?(Array) && value.size == 1
      value = value.to_s  if value.nil? || value.size == 1
      value = nil.to_s    if value.empty?

      value
    end

    def set_attr(name, value)
      @attributes[name.to_sym] = encode_field name, value
    end

    # Reads the array of values for the provided attribute. The
    # attribute name is canonicalized prior to reading. Returns an empty
    # array if the attribute does not exist.
    alias [] get_attr
    alias []= set_attr

    # Weird fluke with flattening, probably because of above attribute
    def to_ary; end

    def to_s
      cn
    end

    def inspect
      "<#{self.class} #{self}>"
    end

    def method_missing(name, args = []) # :nodoc:
      name = name.to_s.downcase

      return set_attr(name[0..-2], args) if name[-1] == '='

      valid_attribute?(name.to_sym) ? get_attr(name) : super(name.to_sym, args)
    end

    def respond_to_missing?(name)
      valid_attribute?(name.to_sym) || super(name.to_sym)
    end
  end
end
