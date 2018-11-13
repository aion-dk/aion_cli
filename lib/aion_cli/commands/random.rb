require 'securerandom'
require 'set'
require 'aion_cli/helpers/application_helper'
require 'aion_cli/helpers/unique_string_generator'

module AionCLI
  module CLI
    class Random < Thor
      include AionCLI::ApplicationHelper

      VALID_CODE_CHARS = %w(A B C D E F G H J K L M N P Q R T U V X Y Z 2 3 4 6 7 8 9)

      desc 'add_election_code CSV_FILE', 'Add a column with a secure random unique election code'
      def add_election_code(path)
        headers, *rows = read_spreadsheet(path)

        length = ask_natural_number('Pick the length of the election code')
        generator = UniqueStringGenerator.new do
          length.times.map { VALID_CODE_CHARS[SecureRandom.random_number(VALID_CODE_CHARS.size)] }.join
        end

        ask_output do |csv|
          csv << headers + ['election_code']
          rows.each do |row|
            csv << row + [generator.get]
          end
        end
      end

      desc 'unique_number MINIMUM MAXIMUM', 'Add a column with a secure random unique number'
      def add_unique_number(path)
        headers, *rows = read_spreadsheet(path)

        min = ask_natural_number('Pick the minimum')
        max = ask_natural_number('Pick the maximum')

        generator = UniqueStringGenerator.new do
          (min + SecureRandom.random_number(max - min)).to_s
        end

        ask_output do |csv|
          csv << headers + ['unique_number']
          rows.each do |row|
            csv << row + [generator.get]
          end
        end
      end

    end

  end
end