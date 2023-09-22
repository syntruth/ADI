module ADI
  # AD Entry for Group
  class Group < Base
    include Member

    def self.filter # :nodoc:
      Net::LDAP::Filter.eq(:objectClass, 'group')
    end

    def self.required_attributes # :nodoc:
      { objectClass: %w[top group] }
    end

    def reload # :nodoc:
      @member_users_non_r  = nil
      @member_users_r      = nil
      @member_groups_non_r = nil
      @member_groups_r     = nil
      @groups              = nil
      super
    end

    # Returns true if the passed User or Group object belongs to this group. For
    # performance reasons, the check is handled by the User or Group object
    # passed.
    def member?(user)
      user.member_of?(self)
    end

    # Add the passed User or Group object to this Group. Returns true if the
    # User or Group is already a member of the group, or if the operation to add
    # them succeeds.
    def add(member)
      return false unless member.is_a?(User) || member.is_a?(Group)

      group_modify(:add) ? true : member?(member)
    end

    # Remove a User or Group from this Group. Returns true if the User or Group
    # does not belong to this Group, or if the oepration to remove them
    # succeeds.
    def remove(member)
      return false unless member.is_a?(User) || member.is_a?(Group)

      group_modify(:delete) ? true : !member?(member)
    end

    def group_modify(operation)
      args = {
        dn:         distinguishedName,
        operations: [[operation, :member, member.distinguishedName]]
      }

      self.class.ldap.modify args
    end

    def members?
      return false unless @entry.respond_to? :member

      return false if @entry.member.nil? || @entry.member.empty?

      true
    end

    # Returns an array of all User objects that belong to this group.
    #
    # If the recursive argument is false, then only Users who belong explicitly
    # to this Group are returned.
    #
    # If the recursive argument is true, then all Users who belong to this
    # Group, or any of its subgroups, are returned.
    def member_users(recursive = false)
      @member_users = users_find @entry.member

      return @member_users unless recursive

      member_groups.each { |g| @member_users += g.member_users(true) }

      @member_users.uniq
    end

    # Returns an array of all Group objects that belong to this group.
    #
    # If the recursive argument is false, then only Groups that belong
    # explicitly to this Group are returned.
    #
    # If the recursive argument is true, then all Groups that belong to this
    # Group, or any of its subgroups, are returned.
    def member_groups(recursive = false)
      @member_groups ||= groups_find(@entry.member)

      return @member_groups unless recursive

      member_groups.each { |g| @member_groups += g.member_groups(true) }

      @member_groups.uniq
    end

    # Returns an array of Group objects that this Group belongs to.
    def groups
      return [] if memberOf.nil?

      @groups ||= groups_find(@entry.memberOf)
    end

    def groups_find(dgn)
      Group.find(:all, distinguishedname: dgn).delete_if(&:nil?)
    end

    def users_find(dgn)
      User.find(:all, distinguishedname: dgn).delete_if(&:nil?)
    end
  end
end
