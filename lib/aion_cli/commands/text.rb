require 'aion_cli/helpers/application_helper'
require 'aion_cli/helpers/cpr_parser'

module AionCLI
  module CLI
    class Text < Thor
      include AionCLI::ApplicationHelper

      desc 'to_csv TEXT_FILE [COLUMN_WIDTHS]', 'Convert to UTF-8 file'
      long_desc <<-LONG_DESC
        Guesses the encoding of TEXT_FILE.\n
        Outputs the file as a UTF-8 file.
      LONG_DESC
      def to_csv(path, column_widths = nil)



        if column_widths and column_widths =~ /^\d+(,\d+)*$/
          _column_widths = column_widths.split(',').map(&:to_i)

          absolute_path = File.absolute_path(path)
          rows = read_file(absolute_path)


          $stdout << CSV.generate(col_sep: ';') do |out|
            rows.each_line do |line|
              offset = 0
              out << _column_widths.map { |size|
                text = line[offset,size]
                offset += size
                text&.strip
              }
            end
          end
        else
          $stderr << "You must specify at least 1 column width\n"
        end

      end

      desc 'to_lf TEXT_FILE', 'Convert CR or CRLF to LF'
      def to_lf(path)
        absolute_path = File.absolute_path(path)
        $stdout << read_file(absolute_path).gsub(/\r\n?/, "\n")
      end

      desc 'cpr_to_csv TEXT_FILE', 'Converts a CPR data file into a UTF-8 csv file'
      def cpr_to_csv(path)
        absolute_path = File.absolute_path(path)
        rows = read_file(absolute_path)

        cpr_parser = CPRParser.new
        records = {}

        # TODO: investigate why line lengths differ
        line_length = Set.new

        rows.each_line do |line|
          record_type = line[0, 3]

          line_length << "#{record_type}: #{line.length}"

          case record_type
          when '000'
            # start record
            production_date = line[19, 8]
          when '999'
            # end record
          when *cpr_parser.supported_record_types
            cpr_no, record = cpr_parser.parse_line(line)
            if records.key?(cpr_no)
              records[cpr_no].merge!(record)
            else
              records[cpr_no] = record
            end
          end
        end

        line_length.sort.each{ |ll| puts ll }

        selected_attributes = []
        if yes?('Would you like to extract default columns? (CPR, Adresseringsnavn, Køn, Fødselsdato, Etiketteadresse)')
          selected_attributes = %i(adrnvn koen foed_dt standardadr)
        else
          available_attributes = cpr_parser.available_attributes
          indices = ask_header_indexes(available_attributes.values, 'Pick the columns to extract (CPR is included)')
          selected_attributes = available_attributes.keys.values_at(*indices)
        end

        ask_output do |csv|
          csv << ['cpr'] + selected_attributes.map(&:to_s)
          records.each do |cpr_no, attributes|
            csv << [cpr_no] + selected_attributes.map{ |attr_name| attributes[attr_name].try(:strip) }
          end
        end
      end

    end
  end
end