require 'set'
require 'faker'
require 'csv'

module AionCLI
  module CLI
    class TestData < Thor
      VALID_CODE_CHARS = %w(A B C D E F G H J K L M N P Q R S T U V X Y Z 2 3 4 5 6 7 8 9)

      desc 'valid_voters ROWS', 'Print secure random unique election codes'
      long_desc <<-LONG_DESC
        ...
      LONG_DESC

      def valid_voters(rows_s)
        rows = rows_s.to_i
        raise ArgumentError, 'Argument must be a positive number between 1 and 1000000' unless 1 <= rows && rows <= 1000000

        factor1_generator = UniqueStringGenerator.new { (10000000 + SecureRandom.random_number(99999999 - 10000000)).to_s }
        factor2_generator = UniqueStringGenerator.new { 9.times.map { VALID_CODE_CHARS[SecureRandom.random_number(VALID_CODE_CHARS.size)] }.join('') }

        col_sep = Faker::Boolean.boolean(0.8) ? ';' : ','

        encodings = [
            Encoding::ISO_8859_1,
            Encoding::UTF_8
        ]

        districts = (1..5).map { |n| "District #{n}"}

        age_groups = [
            '18-30 år',
            '18-30 år',
            '18-30 år',
            '31-40 år',
            '31-40 år',
            '41-50 år',
            '41-50 år',
            '51-60 år',
            '61-70 år',
            '71-80 år',
            '81-90 år',
            '91-100 år',
            'over 100 år'
        ]

        CSV($stdout, col_sep: col_sep, encoding: encodings.sample) do |csv|
          csv << %w(factor1 factor2 district weight age_group)

          rows.times do
            csv << [
                factor1_generator.get,
                factor2_generator.get,
                districts.sample,
                Faker::Number.between(1, 200),
                age_groups.sample
            ]
          end
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