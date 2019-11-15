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
      when '.xlsx'
        size = File.size(absolute_path)
        size_mb = (size / 1024.0 / 1024.0).round
        if size_mb > 5
          say("The XSLT file #{absolute_path} is ~ #{size_mb}MB.")
          say('To improve the speed, consider converting the file to a csv.')
          unless yes?('Would you like to continue?', :yellow)
            say('Done', :green)
            exit 0
          end
        end
        table = Roo::Spreadsheet.open(absolute_path)
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
      # Remove BOM from contents
      content.sub!("\xEF\xBB\xBF", '')
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
          say("'#{index_str}' is not a valid column index", :red)
          next
        end

        index = index_str.to_i

        if index < 0 || index >= headers.size
          say("'#{index_str}' is not a valid column index", :red)
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

        unless indexes_str.match(/^\s*(\d+\s*,\s*)*\d+\s*$/)
          say("'#{indexes_str}' is not a valid column selection", :red)
          next
        end

        indexes = indexes_str.scan(/\d+/).to_a.map(&:to_i)

        if indexes.any? { |index| index < 0 || index >= headers.size }
          say("'#{indexes_str}' is not a valid column selection", :red)
          next
        end

        return indexes
      end
    end

    def ask_header_indexes_for_sort(headers, message)
      loop do
        say(message)
        headers.each.with_index do |name, i|
          say("#{i}) #{name}\n")
        end

        indexes_str = ask("Sort order (fx. 0,-2,3):")

        unless indexes_str.match(/^\s*(-?\d+\s*,\s*)*-?\d+\s*$/)
          say("'#{indexes_str}' is not a valid sort order", :red)
          next
        end

        matches = indexes_str.scan(/(-)?(\d+)/).to_a

        sort_order = matches.map { |m| [m[0] == '-', m[1].to_i] }

        if sort_order.any? { |_, index| index >= headers.size }
          say("'#{indexes_str}' is not a valid sort order", :red)
          next
        end

        return sort_order
      end
    end

    def ask_natural_number(message)
      loop do
        say(message)

        number_str = ask("Number:")

        unless number_str.match(/^\s*\d+\s*$/)
          say("'#{number_str}' must be a number greater than or equal to zero", :red)
          next
        end

        return number_str.to_i
      end
    end

    def ask_date_string(message, allow_blank = false)
      loop do
        say(message)

        date = ask("Date (YYYY-MM-DD):")

        unless allow_blank || date.match(/^\d{4}\-\d{2}\-\d{2}$/)
          say("'#{date}' is invalid. Date must have this format -> YYYY-MM-DD", :red)
          next
        end

        return date
      end
    end

    def output(path, &block)
      CSV.open(path, 'w+', col_sep: ';', &block)
    end

    def ask_output(&block)
      output_path = ask_output_path
      CSV.open(output_path, 'w+', col_sep: ';', &block)
      say("Done! Output stored in #{output_path}", :green)
    end

    def ask_output_path(extname = '.csv', default_name = 'out')
      loop do
        output_path = ask("Pick a name for the output file (default: #{default_name}#{extname}):")
        output_path = default_name if output_path.strip == ''
        output_path += extname if File.extname(output_path) != extname

        absolute_output_path = File.expand_path(output_path)

        if File.exists?(absolute_output_path)
          if yes?('The file already exists. Would you like to overwrite?', :yellow)
            File.unlink(absolute_output_path)
          else
            next
          end
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
          say("Already exists: #{absolute_output_dir}", :red)
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