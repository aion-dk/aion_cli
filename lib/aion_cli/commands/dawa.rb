require 'aion_cli/helpers/csv_helper'
require 'aion_cli/helpers/dawa_client'

module AionCLI
  module CLI
    class Dawa < Thor
      include AionCLI::CsvHelper

      desc 'scan_address CSV_FILE', 'Convert to semi-colon separated UTF-8 csv file'

      def validate_address(path)
        absolute_path = File.absolute_path(path)
        rows = read_csv(absolute_path, col_sep: ';')

        dawa_client = AionCLI::DAWAClient.instance

        rows.each do |row|
          input_string = row[0]
          dawa_guid = dawa_client.address_guid(input_string)
          $stdout << CSV.generate_line([input_string,dawa_guid], col_sep: ';')
          $stdout.flush
        end

      end

    end
  end
end