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

      desc 'concat_text_files TEXT_FILES', 'Concatenates several text files'
      def concat_text_files(*paths)
        out_path = ask_output_path('.txt')
        File.open(out_path, 'w+') do |f|
          paths.each do |path|
            absolute_path = File.absolute_path(path)
            f.write(read_file(absolute_path))
          end
        end
        say "Concatenated #{paths.size} files"
      end

      desc 'filter_multi_lines TEXT_FILE', 'Extracts lines from a text file that appear between two regex matches'
      def filter_multi_lines(path)
        start_regex = ""
        stop_regex = ""

        until start_regex.is_a? Regexp
          begin
            start_regex = Regexp.new(ask("Specify the regex to start line extract"))
            say "Interpreted as: #{start_regex.inspect}"
          rescue
            start_regex = ""
            say "Could not parse regex", :yellow
          end
        end
        until stop_regex.is_a? Regexp
          begin
            stop_regex = Regexp.new(ask("Specify the regex to end line extract"))
            say "Interpreted as: #{stop_regex.inspect}"
          rescue
            stop_regex = ""
            say "Could not parse regex", :yellow
          end
        end

        absolute_path = File.absolute_path(path)
        file_lines = read_file(absolute_path).lines

        storage_enabled = false
        keep_lines = []
        file_lines.each do |line|
          storage_enabled = true if line.match? start_regex
          storage_enabled = false if line.match?(stop_regex)
          keep_lines << line if storage_enabled
        end

        puts "Total lines within match criterias: #{keep_lines.size}"

        out_path = ask_output_path('.txt')
        File.open(out_path, 'w+') do |f|
          f.write(keep_lines.join)
        end
      end

      desc 'cpr_to_csv TEXT_FILE', 'Converts a CPR data file into a UTF-8 csv file'
      def cpr_to_csv(path)
        absolute_path = File.absolute_path(path)
        rows = read_file(absolute_path)

        cpr_parser = CPRParser.new
        records = {}
        unsupported_record_types = Hash.new(0)

        rows.each_line do |line|
          record_type = line[0, 3]

          case record_type
          when '000' # start record
          when '999' # end record
          when *cpr_parser.supported_record_types
            cpr_no, record = cpr_parser.parse_line(line)

            current_record = records[cpr_no] || {}
            records[cpr_no] = current_record.merge(record)
          else
            unsupported_record_types[record_type] += 1
          end
        end


        if unsupported_record_types.present?
          say("The following record types are not supported: #{unsupported_record_types.keys.map(&:inspect).join(', ')}", :yellow)
        end

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
