module ADI
  module FieldType
    # Type: Date
    class Date
      # Converts a time object into an ISO8601 format compatable with Active
      # Directory
      def self.encode(local_time)
        local_time.strftime '%Y%m%d%H%M%S.0Z'
      end

      # Decodes an Active Directory date when stored as ISO8601
      def self.decode(remote_time)
        Time.parse(remote_time)
      end
    end
  end
end
