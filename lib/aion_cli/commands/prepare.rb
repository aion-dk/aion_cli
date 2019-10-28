require 'roo'
require 'csv'
require 'aion_cli/helpers/application_helper'
require 'aion_cli/helpers/dawa_client'
require 'time'
require 'date'
require 'aion_cli/helpers/unique_string_generator'
require 'json'
require 'aion_cli/commands/table'

module AionCLI
  module CLI
    class Prepare < Thor
      include AionCLI::ApplicationHelper

      desc 'full CSV_FILE', 'Select which data you wish to prepare in a CSV file'
      def full(path)

        say
        say('Step 1: Data validation', :bold)

        data_validation(path)

        ask("Hit enter to continue to 'Step 2: Data preparation'", :green)

        say
        say('Step 2: Data preparation', :bold)

        result_path = data_preparation(path)

        say
        ask("Hit enter to continue to 'Step 3: File separation'", :green)

        say
        say('Step 3: File separation', :bold)

        data_separation(result_path)

        say
        say('Done! ', :bold)

      end

      desc 'add_age CSV_FILE DATE-optional', 'Add age calculated from CPR. DATE defaults to "Today"'
      def add_age(path, date = nil)
        date = date.nil? ? Date.today : Date.parse(date)
        headers, *rows = read_spreadsheet(path)
        index_cpr = ask_header_index(headers, 'Specify CPR column.')

        ask_output do |csv|
          rows.each do |row|
            cpr = row[index_cpr]
            year = cpr[4..5].to_i
            day = cpr[0..1].to_i
            month = cpr[2..3].to_i
            birthdate = nil

            case cpr[6].to_i
            when 0..3
              birthdate = "19#{year}-#{month}-#{day}"
            when 4
              case year
              when 0..36
                birthdate = "20#{year}-#{month}-#{day}"
              when 37..99
                birthdate = "19#{year}-#{month}-#{day}"
              end
            when 5..8
              case year
              when 0..57
                birthdate = "20#{year}-#{month}-#{day}"
              when 58..99
                birthdate = "18#{year}-#{month}-#{day}"
              end
            when 9
              case year
              when 0..36
                birthdate = "20#{year}-#{month}-#{day}"
              when 37..99
                birthdate = "19#{year}-#{month}-#{day}"
              end
            end

            difference = (date - Date.parse(birthdate)).to_i
            modulus = difference/365/4
            age = (difference-modulus)/365
            puts age
            row << age
          end

          csv << headers + ['Age']

          rows.each do |row|
            csv << row
          end
        end
      end

      private

      def data_validation(path)
        headers, *rows = read_spreadsheet(path)

        # Select validation commands
        command_headers = ['CPR','EMAIL','ADDRESS','PHONE NUMBER','[ Skip ]']
        validation_types = ask_header_indexes(command_headers, 'Specify what should be validated')
        say

        # Variables used to generate result, based on selected validation commands
        counts_validation = Hash.new(0)
        counts_empty_check = Hash.new(0)

        index_cpr, index_addr, index_email, indexes_empty_check, index_phone = nil

        # Get column indexes of each selected validation type
        validation_types.each do |type|
          case type
          when 0
            index_cpr = ask_header_index(headers, 'Specify the CPR column')
          when 1
            index_email = ask_header_index(headers, 'Specify the EMAIL column')
          when 2
            index_addr = ask_header_index(headers, 'Specify the ADDRESS column')
            say 'Address validation is very time consuming, consider only using a sample!', :yellow
            sample = yes?('Do you want to use a sample of the addresses when validating?', :yellow); say
          when 3
            index_phone = ask_header_index(headers, 'Specify the PHONE NUMBER column')
          end
        end

        check_empty = yes?('Do you wants to check for empty values in other fields?')
        indexes_empty_check = ask_header_indexes(headers, 'Specify which columns you want to check for empty values') if check_empty

        dawa_client = AionCLI::DAWAClient.instance

        # Iterate through selected validations and perform validation --> output to csv
        # CPR validation
        if validation_types.include?(0)

          # Build doublet index
          dict = Hash.new { |h,k| h[k] = [] }
          rows.each.with_index(2) do |row, line_number|
            key = row[index_cpr]
            unless key.blank?
              dict[key] << line_number
            end
          end

          rows.each do |row|
            cpr = row[index_cpr]
            if cpr.blank?
              counts_validation[:cpr_empty] += 1
            elsif dict[cpr].size > 1
              counts_validation[:cpr_doublets] += 1
            else
              valid = validate_cpr(cpr)
              counts_validation[:cpr_invalid] += 1 unless valid
            end
          end
        end

        #EMAIL validation
        if validation_types.include?(1)
          rows.each do |row|
            email = row[index_email]
            if email.blank?
              counts_validation[:email_empty] += 1
            else
              valid = validate_email(email)
              counts_validation[:email_invalid] += 1 unless valid
            end
          end
        end

        #ADDRESS validation
        if validation_types.include?(2)
          addr_tested = 0
          rows.each do |row|
            addr = row[index_addr]
            if addr.blank?
              counts_validation[:addr_empty] += 1
            else
              unless addr_tested > 25 && sample
                valid = validate_addr(addr, dawa_client)
                counts_validation[:addr_not_found] += 1 unless valid
                addr_tested += 1
              end
            end
          end
        end

        #PHONE NUMBER validation
        if validation_types.include?(3)
          rows.each do |row|
            phone = row[index_phone]
            if phone.blank?
              counts_validation[:phone_empty] += 1
            else
              valid = validate_phone_number(phone)
              counts_validation[:phone_invalid] += 1 unless valid
            end
          end
        end

        #EMPTY check
        if check_empty
          indexes_empty_check.each do |index|
            rows.each do |row|
              if row[index].blank?
                counts_empty_check[headers[index]] += 1
              end
            end
          end
        end

        #RESULTS of validation
        say '------------------------'
        say
        say 'Validation result:'
        if counts_validation.length > 0
          counts_validation.each {|key, value| say "#{key} = #{value}", :red}
        else
          say
          say 'No problems detected in validation of selected columns.', :green
        end

        if check_empty
          say
          say 'Empty check result:'

          if counts_empty_check.length > 0
            counts_empty_check.each {|key, value| say "#{key} has #{value} empty values", :yellow}
          else
            say 'No empty values detected in the selected columns.', :green
          end
        end
        say
        say '------------------------'
        say
      end

      #Chars for data prep (generating election codes and voter id's)
      VALID_CODE_CHARS = %w(A B C D E F G H J K L M N P Q R T U V X Y Z 2 3 4 6 7 8 9)
      VALID_ID_CHARS = %w(1 2 3 4 5 6 7 8 9)

      def data_preparation(path)
        headers, *rows = read_spreadsheet(path)

        command_clean_headers = ['CPR (-> 0101862030)','Phone Number  (-> 11223344)','Date of Birth  (-> DDMMYY)','[ Skip ]']
        command_prepare_headers = ['Election Codes','Voter IDs','Date of Birth  (CPR needed)','[ Skip ]']

        command_date_headers = ['DD/MM/YYYY','MM/DD/YYYY','DD-MM-YYYY','MM-DD-YYYY','DDMMYY']

        clean_types = ask_header_indexes(command_clean_headers, 'Specify what existing fields should be cleaned')
        say
        prepare_types = ask_header_indexes(command_prepare_headers, 'Specify what should be added to the file')
        say

        # Variables used to generate result, based on selected formatting commands
        counts_cleaned = Hash.new(0)
        index_cpr, index_dob, index_phone, length_code, length_id, date_type = nil
        n_headers = headers

        clean_types.each do |type|
          case type
          when 0
            index_cpr = ask_header_index(headers, 'Specify the CPR column')
            n_headers += [headers[index_cpr]+'_cleaned']
          when 1
            index_phone = ask_header_index(headers, 'Specify the PHONE NUMBER column')
            n_headers += [headers[index_phone]+'_cleaned']
          when 2
            index_dob = ask_header_index(headers, 'Specify the DATE OF BIRTH column')
            n_headers += [headers[index_dob]+'_cleaned']

            say
            say 'Example data in DATE column:', :bold
            rows[0..3].each do |row|
              say row[index_dob], :green
            end
            index_date_type = ask_header_index(command_date_headers, 'Specify the format of the dates in DATE column')

            case index_date_type
            when 0; date_type = '%d/%m/%Y'
            when 1; date_type = '%m/%d/%Y'
            when 2; date_type = '%d-%m-%Y'
            when 3; date_type = '%m-%d-%Y'
            when 4; date_type = '%d%m%Y'
            end
          end
        end

        prepare_types.each do |type|
          case type

          when 0
            length_code = ask_natural_number('Pick the length of the unique election code (RECOMMENDED: 8 or more)')
          when 1
            length_id = ask_natural_number('Pick the length of the unique voter id (RECOMMENDED: 8 or more)')
          when 2
            index_cpr ||= ask_header_index(headers, 'Specify the CPR column')
          end
        end

        say
        say 'Generating file with results', :bold

        result_file = ask_output_path

        output result_file do |csv|

          dict_failed = []

          # -------- Cleaning jobs --------

          #CPR cleaning
          if clean_types.include?(0)
            rows.each.with_index(2) do |row, line_number|
              cpr = row[index_cpr]
              if cpr.blank?
                result = ''
              else
                cpr_cleaned = clean_cpr(cpr)
                if validate_cpr(cpr_cleaned)
                  counts_cleaned[:cpr_clean_success] += 1
                  result = cpr_cleaned
                else
                  counts_cleaned[:cpr_clean_failed] += 1
                  result = ''
                  dict_failed << line_number
                end
              end
              row << result
            end
          end

          #PHONE NUMBER cleaning
          if clean_types.include?(1)
            rows.each do |row|
              phone = row[index_phone]
              if phone.blank?
                phone_cleaned = ''
              else
                phone_cleaned = clean_phone(phone)
                phone_cleaned ? counts_cleaned[:phone_clean_success] += 1 : counts_cleaned[:phone_clean_failed] += 1
              end
              row << phone_cleaned
            end
          end

          #DOB cleaning
          if clean_types.include?(2)
            rows.each do |row|
              dob = row[index_dob]
              if dob.blank?
                dob_cleaned = ''
              else
                dob_cleaned = clean_dob(dob, date_type)
                dob_cleaned ? counts_cleaned[:dob_clean_success] += 1 : counts_cleaned[:dob_clean_failed] += 1
              end
              row << dob_cleaned
            end
          end

          # -------- Addition jobs --------

          # Add unique ELECTION CODE
          if prepare_types.include?(0)
            generator = UniqueStringGenerator.new do
              length_code.times.map { VALID_CODE_CHARS[SecureRandom.random_number(VALID_CODE_CHARS.size)] }.join
            end

            n_headers += ['election_code']
            rows.each do |row|
              row << generator.get
            end
          end

          # Add unique VOTER ID
          if prepare_types.include?(1)
            generator = UniqueStringGenerator.new do
              length_id.times.map { VALID_ID_CHARS[SecureRandom.random_number(VALID_ID_CHARS.size)] }.join
            end

            n_headers += ['voter_id']
            rows.each do |row|
              row << generator.get
            end
          end

          #Add DATE OF BIRTH (from CPR)
          if prepare_types.include?(2)
            n_headers += ['date_of_birth']
            rows.each do |row|
              row << row[index_cpr][0..5]
            end
          end

          #Gather result in a csv
          csv << n_headers

          rows.each do |row|
            csv << row
          end

          #Gather fails in a csv
          say
          say 'Generating file with faulty data rows', :bold
          faulty_file = ask_output_path
          output faulty_file do |csv_failed|
            csv_failed << headers
            dict_failed.uniq.each do |line_number|
              csv_failed << rows[line_number]
            end
          end

          return result_file
        end
      end

      def data_separation(path)
        headers, *rows = read_spreadsheet(path)

        # Select validation commands
        command_headers = ['Votes','Cards','Candidacy','[ Skip ]']
        slice_types = ask_header_indexes(command_headers, 'Specify what systems you need files for')
        say
        customer = ask("Input customer initials for file naming (i.e. AV, JØP, HK, ..):")

        return if slice_types.include?(3)
        slice_types.each do |t|
          file_suffix = command_headers[t]
          say
          say  "Slicing file for #{file_suffix}...", [:cyan, :bold]

          slice_file(path, customer, file_suffix)
        end
      end

      def validate_cpr(cpr)
        cpr_regex = /^(?:(?:31(?:0[13578]|1[02])|(?:30|29)(?:0[13-9]|1[0-2])|(?:0[1-9]|1[0-9]|2[0-8])(?:0[1-9]|1[0-2]))[0-9]{2}-?[0-9]|290200-?[4-9]|2902(?:(?!00)[02468][048]|[13579][26])-?[0-3])[0-9]{3}|000000-?0000$/
        !!cpr.match(cpr_regex)
      end

      def validate_addr(addr, client)
        address = client.address(addr)
        address.present?
      end

      def validate_email(email)
        email_regex = URI::MailTo::EMAIL_REGEXP
        !!email.match(email_regex)
      end

      def validate_phone_number(phone_number)
        dk_phone_regex = /(?:45\s?)?(?:\d{2}\s?){3}\d{2}/
        !!phone_number.match(dk_phone_regex)
      end

      def clean_cpr(cpr)
        cpr.tr('^0-9','')
      end

      def clean_phone(phone)
        phone_cleaned = phone.tr('^0-9','')
        phone_cleaned if phone_cleaned.length == 8 || phone_cleaned.length == 10 && phone_cleaned[0..1] == '45'
      end

      def clean_dob(date,format)
        begin Date.strptime(date, format).strftime('%d%m%y') rescue nil end
      end

      def slice_file(path, prefix, suffix)
        rows = read_spreadsheet(path)
        indexes = ask_header_indexes(rows.first, "Pick the columns to keep")
        file_name = "#{prefix}_#{suffix}.csv"
        output_path = File.expand_path(file_name)

        if File.exists?(output_path)
          if yes?("The file #{file_name} already exists. Would you like to overwrite?", :yellow)
            File.unlink(output_path)
          else
            return
          end
        end

        output output_path  do |csv|
          rows.each do |row|
            csv << row.values_at(*indexes)
          end
          say "Generated file for #{suffix}.", :green
        end
      end
    end
  end
end
