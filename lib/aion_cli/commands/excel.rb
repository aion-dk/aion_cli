require 'roo'
require 'csv'

module AionCLI
  module CLI
    class Excel < Thor

      desc 'to_csv', 'Convert Excel file to CSV'
      long_desc <<-LONG_DESC
        Convert Excel file, default_sheet (first sheet) to csv\n
        With rejection of top and left padding cells.
      LONG_DESC

      option :s, banner: "Sheet number"
      def to_csv(path)
        absolute_path = File.absolute_path(path)
        xlsx = Roo::Spreadsheet.open(absolute_path)
        target_csv_path = csv_filename(path)

        unless options[:s].nil?
          sheet_number = options[:s].to_i
          xlsx.default_sheet = xlsx.sheets[sheet_number]
        end

        CSV.open(target_csv_path, 'wb') do |csv|
          xlsx.each_row_streaming() do |row|
            csv << row
          end
        end

      end

      private
        def csv_filename(path)
          csv_path_parts     = path.split('/')
          csv_filename       = csv_path_parts[-1].sub(/\.\w+$/, '.csv')
          csv_path_parts[-1] = csv_filename
          csv_path_parts.join '/'
        end

    end
  end
end