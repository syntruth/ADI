module ADI
  module FieldType
    # Type: Timestamp
    class Timestamp
      AD_DIVISOR = 10_000_000     # :nodoc:
      AD_OFFSET  = 11_644_473_600 # :nodoc:

      # Encodes a local Time object (or the number of seconds since January 1,
      # 1970) into a timestamp that the Active Directory server can understand
      # (number of 100 nanosecond time units since January 1, 1600)
      def self.encode(time)
        (time.to_i + AD_OFFSET) * AD_DIVISOR
      end

      # Decodes an Active Directory timestamp (the number of 100 nanosecond time
      # units since January 1, 1600) into a Ruby Time object.
      def self.decode(time)
        Time.at (time.to_i / AD_DIVISOR) - AD_OFFSET
      end
    end
  end
end
