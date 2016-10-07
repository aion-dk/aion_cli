require 'csv'
require 'charlock_holmes'

module AionCLI
  module CsvHelper

    def read_csv(path, options = {})
      content = read_file(path)
      options[:col_sep] ||= detect_col_sep(content)
      CSV.parse(content, options)
    end

    # CSV Helpers
    def read_file(path)
      content = File.read(path)
      detection = CharlockHolmes::EncodingDetector.detect(content)
      CharlockHolmes::Converter.convert(content, detection[:encoding], 'UTF-8')
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