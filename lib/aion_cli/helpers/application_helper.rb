require 'csv'
require 'charlock_holmes'

module AionCLI
  module ApplicationHelper

    protected

    def read_spreadsheet(path)
      absolute_path = File.expand_path(path)
      case File.extname(path)
      when '.csv'
        table = read_csv(path)
      else
        table = Roo::Spreadsheet.open(absolute_path)
      end

      rows = []
      table.each do |row|
        rows << row.map(&:to_s)
      end

      rows
    end

    def read_csv(path, options = {})
      absolute_path = File.expand_path(path)
      content = read_file(absolute_path)
      options[:col_sep] ||= detect_col_sep(content)
      CSV.parse(content, options)
    end

    # CSV Helpers
    def read_file(path)
      content = File.read(path)
      detection = CharlockHolmes::EncodingDetector.detect(content)
      CharlockHolmes::Converter.convert(content, detection[:encoding], 'UTF-8')
    end

    def ask_header_index(headers, message)
      loop do
        say(message)
        headers.each.with_index do |name, i|
          say("#{i}) #{name}\n")
        end

        index_str = ask("Column index:")

        unless index_str.match(/^\s*\d+\s*$/)
          say("'#{index_str}' is not a valid column index (reg)")
          next
        end

        index = index_str.to_i

        if index < 0 || index >= headers.size
          say("'#{index_str}' is not a valid column index")
          next
        end

        return index
      end

    end

    def ask_header_indexes(headers, message)
      loop do
        say(message)
        headers.each.with_index do |name, i|
          say("#{i}) #{name}\n")
        end

        indexes_str = ask("Column selection (fx. 3,1,2):")

        unless indexes_str.match(/^\s*(\d+\s*,\s*)?\d+\s*$/)
          say("'#{indexes_str}' is not a valid column selection")
          next
        end

        indexes = indexes_str.scan(/^\s*\d+\s*$/).to_a.map(&:to_i)


        if indexes.any? { |index| index < 0 || index >= headers.size }
          say("'#{indexes_str}' is not a valid column selection")
          next
        end

        return indexes
      end
    end

    def ask_natural_number(message)
      loop do
        say(message)

        number_str = ask("Number:")

        unless number_str.match(/^\s*\d+\s*$/)
          say("'#{number_str}' must be a number greater than or equal to zero")
          next
        end

        return number_str.to_i
      end
    end

    def output(path, &block)
      CSV.open(path, 'w+', col_sep: ';', &block)
    end

    def ask_output(&block)
      CSV.open(ask_output_path, 'w+', col_sep: ';', &block)
    end

    def ask_output_path(extname = '.csv', default_name = 'out')
      loop do
        output_path = ask("Pick a name for the output file (default: #{default_name}#{extname})")
        output_path = default_name if output_path.strip == ''
        output_path += extname if File.extname(output_path) != extname

        absolute_output_path = File.expand_path(output_path)

        if File.exists?(absolute_output_path)
          say("File already exists: #{absolute_output_path}")
          next
        end

        return absolute_output_path
      end
    end

    def ask_output_dir(default_name = 'out', mkdir: false)
      loop do
        output_dir = ask("Pick a name for the output dir (default: #{default_name})")
        output_dir = default_name if output_dir.blank?

        absolute_output_dir = File.expand_path(output_dir)

        if File.exists?(absolute_output_dir)
          say("Already exists: #{absolute_output_dir}")
          next
        end

        FileUtils.mkdir(absolute_output_dir) if mkdir

        return absolute_output_dir
      end
    end

    def parse_natural_number(integer_str)
      integer_str.to_i if integer_str.match(/^\s*\d+\s*$/)
    end

    private

    def detect_col_sep(contents)
      test_contents = contents.lines.first.chomp
      test_results = [',',';',"\t"].map { |col_sep| [count_col_sep(test_contents, col_sep), col_sep ] }
      test_results.sort.last.last
    end

    def count_col_sep(test_contents, col_sep)
      CSV.parse(test_contents, col_sep: col_sep).first.size
    rescue
      0
    end

  end
end