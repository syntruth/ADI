module ADI
  module FieldType
    # Type: Binary
    class Binary
      # Encodes a hex string into a GUID
      def self.encode(hex)
        [hex].pack('H*')
      end

      # Decodes a binary GUID as a hex string
      def self.decode(guid)
        guid.unpack1('H*').to_s
      end
    end
  end
end
