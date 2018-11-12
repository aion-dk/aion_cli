require 'aion_cli/helpers/application_helper'

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

    end
  end
end