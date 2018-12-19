require 'aion_cli/helpers/application_helper'
require 'aion_cli/helpers/dawa_client'

module AionCLI
  module CLI
    class Dawa < Thor
      include AionCLI::ApplicationHelper

      desc 'validate_address CSV_FILE', 'Convert to semi-colon separated UTF-8 csv file'

      def validate_address(path)
        headers, *rows = read_spreadsheet(path)

        column_index = ask_header_index(headers,"Pick the address-column to validate:")

        dawa_client = AionCLI::DAWAClient.instance

        ask_output do |csv|
          csv << headers + ['DAWA-GUID']
          rows.each do |row|
            input_string = row[column_index]
            dawa_guid = dawa_client.address_guid(input_string)
            csv << row + [dawa_guid]
          end
        end
      end
    end

  end
end
