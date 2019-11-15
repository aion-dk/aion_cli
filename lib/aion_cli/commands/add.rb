require 'securerandom'
require 'set'
require 'aion_cli/helpers/application_helper'
require 'aion_cli/helpers/unique_string_generator'

module AionCLI
  module CLI
    class Add < Thor
      include AionCLI::ApplicationHelper

      VALID_CODE_CHARS = %w(A B C D E F G H J K L M N P Q R T U V X Y Z 2 3 4 6 7 8 9)
      VALID_ID_CHARS = %w(1 2 3 4 5 6 7 8 9)

      desc 'election_codes CSV_FILE', 'Add a column with a secure random unique election code'
      def election_codes(path)
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

      desc 'unique_voter_ids CSV_FILE', 'Add a column with a secure random unique voter id'
      def unique_voter_ids(path)
        headers, *rows = read_spreadsheet(path)

        length = ask_natural_number('Pick the length of the unique voter id (RECOMMENDED: 8 or more)')
        generator = UniqueStringGenerator.new do
          length.times.map { VALID_ID_CHARS[SecureRandom.random_number(VALID_ID_CHARS.size)] }.join
        end

        ask_output do |csv|
          csv << ['voter_id'] + headers
          rows.each do |row|
            csv << [generator.get] + row
          end
        end
      end

      desc 'unique_numbers CSV_FILE', 'Add a column with a secure random unique number'
      def unique_numbers(path)
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

      desc 'age CSV_FILE', 'Add age calculated from CPR birthdate to selected date. DATE defaults to "Today"'
      def age(path)
        date = Date.parse(ask_date_string('Input date to calculate age from. (Date defaults "Today" if blank)'))
        if date == ""
          date = Date.today
        end
        headers, *rows = read_spreadsheet(path)
        index_cpr = ask_header_index(headers, 'Specify CPR column.')

        ask_output do |csv|
          rows.each do |row|
            cpr = row[index_cpr]
            year = cpr[4..5].to_i
            year_text = year < 10 ? "0#{year}" : year.to_s
            day = cpr[0..1].to_i
            month = cpr[2..3].to_i
            birthdate = nil

            case cpr[6].to_i
            when 0..3
              birthdate = "19#{year_text}-#{month}-#{day}"
            when 4
              case year
              when 0..36
                birthdate = "20#{year_text}-#{month}-#{day}"
              when 37..99
                birthdate = "19#{year_text}-#{month}-#{day}"
              end
            when 5..8
              case year
              when 0..57
                birthdate = "20#{year_text}-#{month}-#{day}"
              when 58..99
                birthdate = "18#{year_text}-#{month}-#{day}"
              end
            when 9
              case year
              when 0..36
                birthdate = "20#{year_text}-#{month}-#{day}"
              when 37..99
                birthdate = "19#{year_text}-#{month}-#{day}"
              end
            end

            begin
              difference = (date - Date.parse(birthdate)).to_i
            rescue ArgumentError
              difference = ''
            end

            modulus = difference/365/4
            age = (difference-modulus)/365
            row << age
          end

          csv << headers + ['Age']

          rows.each do |row|
            csv << row
          end
        end
      end

    end
  end
end