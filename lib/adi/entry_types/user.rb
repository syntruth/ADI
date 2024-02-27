module ADI
  # AD Entry for User
  class User < Base
    include Member

    UAC_ACCOUNT_DISABLED = 0x0002
    UAC_NORMAL_ACCOUNT   = 0x0200 # 512

    DEFAULT_ATTRIBUTES = %w[
      userAccountControl
      lockoutTime
      directReports
      manager
      samaccountname
      mail
      givenname
      sn
      displayname
    ].freeze

    # Authenticate a User based on the given username (sAMAccountName) and
    # password.
    #
    # Returns: Nil for failure to login or invalid password, or a User instance
    # of the authentication succeeded.
    def self.authenticate(username, pwd)
      # This will try and establish a connection if one is not already set.
      return nil unless ADI.connected?

      # If the password is not a string or has no length, bail out.
      return nil unless pwd.is_a?(String) && pwd.size.positive?

      # Try to bind to the AD host as the user...
      result = ADI.ldap.dup.bind_as filter:   "(sAMAccountName=#{username})",
                                    password: pwd

      # ...and if successful, return a new User instance, else return Nil.
      result ? new(result[0]) : nil
    end

    def self.filter # :nodoc:
      ufilter = Net::LDAP::Filter.eq :objectClass, 'user'
      cfilter = Net::LDAP::Filter.eq :objectClass, 'computer'

      ufilter & ~cfilter
    end

    def self.parse_cn(dgn)
      matches = dgn.match(/CN=(.+?),OU/)

      matches ? matches[1] : nil
    end

    def self.required_attributes # :nodoc:
      { objectClass: %w[top organizationalPerson person user] }
    end

    def self.default_attributes # :nodoc:
      DEFAULT_ATTRIBUTES
    end

    # Try to authenticate the current User against Active Directory
    # using the supplied password. Returns false upon failure.
    #
    # Authenticate can fail for a variety of reasons, primarily:
    #
    # * The password is wrong
    # * The account is locked
    # * The account is disabled
    #
    # User#locked? and User#disabled? can be used to identify the latter
    # two cases, and if the account is enabled and unlocked, Athe
    # password is probably invalid.
    def authenticate(password)
      return false if password.to_s.empty?

      args = {
        filter:   "(sAMAccountName=#{sAMAccountName})",
        password: password
      }

      self.class.ldap.dup.bind_as args
    end

    # Return the User's manager (another User object), depending on what
    # is stored in the manager attribute.
    #
    # Returns nil if the schema does not include the manager attribute
    # or if no manager has been configured.
    def manager
      return nil unless @entry.respond_to?(:manager) && !@entry.manager.nil?

      cn = User.parse_cn @entry.manager.to_s

      cn ? User.find(:first, cn: cn.gsub(/\\/, '')) : nil
    end

    # Returns an array of Group objects that this User belongs to. Only
    # the immediate parent groups are returned, so if the user Sally is
    # in a group called Sales, and Sales is in a group called Marketing,
    # this method would only return the Sales group.
    def groups
      @groups ||= Group.find(:all, distinguishedname: @entry.memberOf)
    end

    # Returns an array of User objects that have this User as their
    # manager.
    def direct_reports
      return [] unless @entry.respond_to?(:directReports) &&
                       !@entry.directReports.nil?

      cns = @entry.directReports.filter_map do |user|
        cn = User.parse_cn user.to_s

        cn.is_a?(String) ? cn.gsub(/\\/, '') : nil
      end

      @direct_reports ||= User.find(:all, cn: cns)
    end

    # Returns true if this account has been locked out (usually because
    # of too many invalid authentication attempts).
    #
    # Locked accounts can be unlocked with the User#unlock! method.
    def locked?
      return false unless @entry.respond_to?(:lockoutTime)

      lockoutTime && lockoutTime.to_i != 0
    end

    # Returns true if this account has been disabled.
    def disabled?
      userAccountControl.to_i & UAC_ACCOUNT_DISABLED != 0
    end

    # Returns true if the user should be able to log in with a correct
    # password (essentially, their account is not disabled or locked
    # out).
    def can_login?
      !disabled? && !locked?
    end

    # Change the password for this account.
    #
    # This operation requires that the bind user specified in Base.setup
    # have heightened privileges. It also requires an SSL connection.
    #
    # If the force_change argument is passed as true, the password will
    # be marked as 'expired', forcing the user to change it the next
    # time they successfully log into the domain.
    def change_password(new_password, force_change = false)
      settings = self.class.settings.dup

      settings.merge port: 636, encryption: { method: :simple_tls }

      ldap  = Net::LDAP.new(settings)
      opers = change_password_operations new_password, force_change

      ldap.modify dn: distinguishedName, operations: opers
    end

    # Unlocks this account.
    def unlock!
      self.class.ldap.replace_attribute(distinguishedName, :lockoutTime, ['0'])
    end

    # String representation
    def to_s
      "#{displayname} (#{samaccountname})"
    end

    # For Sorting lists of User objects.
    def <=>(other)
      unless other.is_a? User
        raise ArgumentError, 'Other argument not ADI::User class!'
      end

      # Sort by displayname, then lastname, then first name, then account name.
      res = displayname    <=> other.displayname
      res = sn             <=> other.sn              if res.zero?
      res = givenname      <=> other.givenname       if res.zero?
      res = samaccountname <=> other.samaaccountname if res.zero?

      res
    end

    private

    def change_password_operations(new_password, force_change)
      pwd = FieldType::Password.encode(new_password)
      fc  = force_change ? '0' : '-1'

      [
        [:replace, :lockoutTime,        ['0']],
        [:replace, :unicodePwd,         [pwd]],
        [:replace, :userAccountControl, [UAC_NORMAL_ACCOUNT.to_s]],
        [:replace, :pwdLastSet,         [fc]]
      ]
    end
  end
end
