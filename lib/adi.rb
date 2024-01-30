require 'net/ldap'

require_relative 'adi/nil_filter'
require_relative 'adi/cache/cache'
require_relative 'adi/finder/finder'
require_relative 'adi/query/query'
require_relative 'adi/entry_types/base'
require_relative 'adi/entry_types/container'
require_relative 'adi/entry_types/member'
require_relative 'adi/entry_types/user'
require_relative 'adi/entry_types/group'
require_relative 'adi/entry_types/computer'
require_relative 'adi/field_type/password'
require_relative 'adi/field_type/binary'
require_relative 'adi/field_type/date'
require_relative 'adi/field_type/timestamp'
require_relative 'adi/field_type/dn_array'
require_relative 'adi/field_type/user_dn_array'
require_relative 'adi/field_type/group_dn_array'
require_relative 'adi/field_type/member_dn_array'

# Set up base Active Directory Interface module.
#
# This modules is the interface with Active Directory as a whole.
module ADI
  # This configures the connection to Active Directory and, optionally,
  # sets up default attribute to include when searching for entries if
  # they are included in the config hash.
  #
  # A valid config contains at least the `server` key, which is what is
  # passed to `Net::LDAP` to connect to the Active Directory server.
  #
  # The config may also contain an `attributes` key, which defines array
  # of keys, per entry type (User, Group, etc.) that must be returned
  # when an entry of that type is searched for. For example, if it is
  # desired to return the 'department' attribyte for a user, define a
  # `:user` key with an array of `['department']` and that key will
  # always be included when a User is loaded from Active Directory.
  #
  # Note: If they attribute does exist, it will not be returned and a
  # nil result will exist in its place.
  #
  # See the Net::LDAP library for configuration options for connecting
  # to Active Directory.
  #
  # Example config:
  #
  # {
  #   server: {
  #     host: 'ad-server.example.org',
  #     port: 389,
  #     base: 'dc=example,dc=org',
  #     auth: {
  #       method:   :simple,
  #       username: 'bind_user@example.org',
  #       password: 'password_for_bind_user'
  #     }
  #   },
  #
  #   attributes: {
  #     user: ['department', 'title']
  #   },
  #
  #   cache: {
  #     timeout:        300,
  #     check_interval: 900
  #   }
  # }
  def self.setup(settings)
    @settings       = settings
    @ldap_connected = false
    @ldap           = Net::LDAP.new settings[:server]

    Base.setup settings

    self
  end

  def self.settings
    @settings
  end

  def self.attributes_settings_for(type)
    attrs = settings.fetch :attributes, {}

    attrs.fetch type, []
  end

  def self.error
    code = @ldap.get_operation_result.code
    msg  = @ldap.get_operation_result.message

    "#{code}: #{msg}"
  end

  # Return the last errorcode that ldap generated
  def self.error_code
    @ldap.get_operation_result.code
  end

  # Check to see if the last query produced an error
  #
  # Note: Invalid username/password combinations will not produce errors
  def self.error?
    @ldap.nil? ? false : @ldap.get_operation_result.code != 0
  end

  # Check to see if we are connected to the LDAP server. This method will try
  # to connect, if we haven't already
  def self.connected?
    @ldap_connected ||= @ldap.bind unless @ldap.nil?

    @ldap_connected
  rescue Net::LDAP::NoBindResultError
    false
  end

  # Access to the LDAP connection
  def self.ldap
    @ldap
  end

  ### Special Fields

  def self.special_fields
    @special_fields
  end

  def self.special_fields=(fields)
    @special_fields = fields
  end

  # rubocop:disable Layout/HashAlignment
  # All objects in Active Directory
  self.special_fields = {
    Base: {
      objectguid:  :Binary,
      whencreated: :Date,
      whenchanged: :Date,
      memberof:    :DnArray
    },

    # User objects
    User: {
      objectguid:                      :Binary,
      whencreated:                     :Date,
      whenchanged:                     :Date,
      objectsid:                       :Binary,
      msexchmailboxguid:               :Binary,
      msexchmailboxsecuritydescriptor: :Binary,
      lastlogontimestamp:              :Timestamp,
      pwdlastset:                      :Timestamp,
      accountexpires:                  :Timestamp,
      memberof:                        :MemberDnArray
    },

    # Group objects
    Group: {
      objectguid:  :Binary,
      whencreated: :Date,
      whenchanged: :Date,
      objectsid:   :Binary,
      memberof:    :GroupDnArray,
      member:      :MemberDnArray
    }
  }
  # rubocop:enable Layout/HashAlignment
end
