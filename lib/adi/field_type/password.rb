module ADI
  module FieldType
    # Type: Password
    class Password
      # Encodes an unencrypted password into an encrypted password that the
      # Active Directory server will understand.
      def self.encode(password)
        ("\"#{password}\"".chars.map { |c| "#{c}\000" }).join
      end

      # Always returns nil, since you can't decrypt the User's encrypted
      # password.
      def self.decode(_hashed)
        nil
      end
    end
  end
end
