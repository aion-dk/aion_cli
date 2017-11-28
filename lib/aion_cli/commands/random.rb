require 'securerandom'
require 'set'

module AionCLI
  module CLI
    class Random < Thor
      VALID_CODE_CHARS = %w(A B C D E F G H J K L M N P Q R S T U V X Y Z 2 3 4 5 6 7 8 9)

      desc 'unique_code ROWS', 'Print secure random unique election codes'
      long_desc <<-LONG_DESC
        ...
      LONG_DESC

      def unique_code(rows)
        if rows and rows =~ /^\d+$/
          generator = UniqueStringGenerator.new { 9.times.map { VALID_CODE_CHARS[SecureRandom.random_number(VALID_CODE_CHARS.size)] }.join('') }
          rows.to_i.times do
            $stdout << generator.get
            $stdout << "\n"
          end
        else
          $stderr << 'ROWS is not specified or not a positive integer'
        end
      end

      desc 'unique_number ROWS', 'Print secure random unique number between 10000000 and 99999999'
      long_desc <<-LONG_DESC
        ...
      LONG_DESC

      def unique_number(rows)
        if rows and rows =~ /^\d+$/
          generator = UniqueStringGenerator.new { (10000000 + SecureRandom.random_number(99999999 - 10000000)).to_s }
          rows.to_i.times do
            $stdout << generator.get
            $stdout << "\n"
          end
        else
          $stderr << 'ROWS is not specified or not a positive integer'
        end
      end

      desc 'to_csv TEXT_FILE [COLUMN_WIDTHS]', 'Convert to UTF-8 file'
      long_desc <<-LONG_DESC
        Guesses the encoding of TEXT_FILE.\n
        Outputs the file as a UTF-8 file.
      LONG_DESC
      def to_csv(path, column_widths = nil)

        if column_widths and column_widths =~ /^\d+(,\d+)*$/
          _column_widths = column_widths.split(',').map(&:to_i)

          absolute_path = File.absolute_path(path)
          lines = read_file(absolute_path)

          $stdout << CSV.generate(col_sep: ';') do |out|
            lines.each_line do |line|
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
    end

    protected

    class UniqueStringGenerator

      def initialize(used_values = [], &block)
        @used_values = Set.new(used_values)
        @block = block
      end

      def get
        loop do
          code = @block.call
          next if @used_values.include?(code)
          @used_values.add(code)
          return code
        end
      end

    end

  end
end