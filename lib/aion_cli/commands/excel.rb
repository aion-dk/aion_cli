require 'roo'
require 'csv'
require 'write_xlsx'
require 'aion_cli/helpers/application_helper'

module AionCLI
  module CLI
    class Excel < Thor

      desc 'to_csv', 'Convert Excel file to CSV'
      long_desc <<-LONG_DESC
        Convert Excel file, default_sheet (first sheet) to csv\n
        With rejection of top and left padding cells.
      LONG_DESC

      option :sheet, aliasses: '-s', banner: 'Sheet number'
      def to_csv(path)
        absolute_path = File.absolute_path(path)
        xlsx = Roo::Spreadsheet.open(absolute_path)

        unless options[:s].nil?
          sheet_number = options[:s].to_i
          xlsx.default_sheet = xlsx.sheets[sheet_number]
        end

        ask_output do |csv|
          xlsx.each_row_streaming do |row|
            csv << row
          end
        end

      end

      desc 'to_xlsx', 'Convert a spreadsheet file to XLSX'
      def to_xlsx(csv_path)
        workbook = WriteXLSX.new(ask_output_path('.xlsx'))
        worksheet = workbook.add_worksheet

        bold = workbook.add_format
        bold.set_bold

        headers, *data = read_spreadsheet(csv_path)

        headers.each_with_index do |header, index|
          worksheet.write(0, index, header, bold)
        end

        data.each_with_index do |row, row_i|
          row.each_with_index do |cell, col_i|
            worksheet.write(row_i + 1, col_i, cell)
          end
        end

        workbook.close
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