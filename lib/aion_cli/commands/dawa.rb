require 'aion_cli/helpers/csv_helper'
require 'aion_cli/helpers/dawa_client'

module AionCLI
  module CLI
    class Dawa < Thor
      include AionCLI::CsvHelper

      desc 'validate_address CSV_FILE [COLUMN]', 'Convert to semi-colon separated UTF-8 csv file'

      def validate_address(path, column = nil)
        absolute_path = File.absolute_path(path)
        rows = read_csv(absolute_path, col_sep: ';')

        dawa_client = AionCLI::DAWAClient.instance

        if column && column =~ /^\d+$/
          column_index = column.to_i
          rows.each do |row|
            input_string = row[column_index]
            dawa_guid = dawa_client.address_guid(input_string)
            $stdout << CSV.generate_line([*row,dawa_guid], col_sep: ';')
            $stdout.flush
          end
        else
          $stderr << "Columns selection missing. Define selected Fx. 1,2,0\n"
          rows.first.each_with_index do |name, index|
            $stderr << "#{index}) #{name}\n"
          end
        end

      end

    end
  end
end