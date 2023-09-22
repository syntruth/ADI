module ADI
  module FieldType
    # Type MemberDnArray
    class MemberDnArray
      # Encodes an array of objects into a list of dns
      def self.encode(obj_array)
        obj_array.map(&:dn)
      end

      # Decodes a list of DNs into the objects that they are
      def self.decode(dn_array)
        # Ensures that the objects are cast correctly
        users  = User.find :all, distinguishedname: dn_array
        groups = Group.find :all, distinguishedname: dn_array

        [].tap do |a|
          a.push users  unless users.nil?
          a.push groups unless groups.nil?
        end.flatten
      end
    end
  end
end
