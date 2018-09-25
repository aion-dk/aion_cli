require 'roo'
require 'csv'
require 'write_xlsx'

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
        target_csv_path = csv_filename(path)

        unless options[:s].nil?
          sheet_number = options[:s].to_i
          xlsx.default_sheet = xlsx.sheets[sheet_number]
        end

        CSV.open(target_csv_path, 'wb', col_sep: ';') do |csv|
          xlsx.each_row_streaming() do |row|
            csv << row
          end
        end

      end

      desc 'to_xlsx', 'Convert a CSV file to XLSX'
      long_desc <<-LONG_DESC
        Convert CSV file to XLSX
      LONG_DESC

      option :col_sep, banner: 'CSV column separator', default: ';'
      def to_xlsx(csv_path, xlsx_path)
        absolute_csv_path = File.absolute_path(csv_path)
        absolute_xlsx_path = File.absolute_path(xlsx_path)

        raise "Error: #{csv_path} does not exist" unless File.exists?(absolute_csv_path)
        raise "Error: #{xlsx_path} already exists" if File.exists?(absolute_xlsx_path)

        workbook = WriteXLSX.new(absolute_xlsx_path)
        worksheet = workbook.add_worksheet

        bold = workbook.add_format
        bold.set_bold

        # Write a formatted and unformatted string, row and column notation.

        headers, *data = CSV.read(absolute_csv_path, col_sep: options[:col_sep])

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