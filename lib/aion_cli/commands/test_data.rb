require 'set'
require 'faker'
require 'csv'
require 'aion_cli/helpers/application_helper'
require 'aion_cli/helpers/unique_string_generator'

module AionCLI
  module CLI
    class TestData < Thor
      include ApplicationHelper
      VALID_CODE_CHARS = %w(A B C D E F G H J K L M N P Q R S T U V X Y Z 2 3 4 5 6 7 8 9)

      desc 'generate_voters', 'Generate voters'
      def generate_voters
        rows = ask_natural_number('How many voters?')

        raise ArgumentError, 'Argument must be a positive number between 1 and 1000000' unless 1 <= rows && rows <= 1000000

        factor1_generator = UniqueStringGenerator.new { (10000000 + SecureRandom.random_number(99999999 - 10000000)).to_s }
        factor2_generator = UniqueStringGenerator.new { 9.times.map { VALID_CODE_CHARS[SecureRandom.random_number(VALID_CODE_CHARS.size)] }.join('') }

        col_sep = Faker::Boolean.boolean(0.8) ? ';' : ','

        encodings = [
            Encoding::ISO_8859_1,
            Encoding::UTF_8
        ]

        encoding = encodings.sample

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

        CSV.open(ask_output_path, 'w+', col_sep: col_sep, encoding: encodings.sample) do |csv|
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

        say("rows     : #{rows}")
        say("col_sep  : #{col_sep}")
        say("encoding : #{encoding}")

      end
    end

  end
end