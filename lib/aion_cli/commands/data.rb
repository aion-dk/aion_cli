require 'roo'
require 'csv'
require 'aion_cli/helpers/preparation_helper'
require 'aion_cli/helpers/application_helper'
require 'aion_cli/helpers/dawa_client'
require 'time'
require 'date'
require 'aion_cli/helpers/unique_string_generator'
require 'json'
require 'aion_cli/commands/table'

module AionCLI
  module CLI
    class Data < Thor
      include AionCLI::ApplicationHelper
      include AionCLI::PreparationHelper

      desc 'blur_statistics CSV_FILE', 'Blur a statistics category when less than a specified value is present in the category'
      def blur_statistics(path)
        data_blur(path)
      end

      desc 'validate CSV_FILE', 'Select which data you wish to validate in a CSV file'
      def validate(path)
        data_validation(path)
      end

      desc 'prepare CSV_FILE', 'Select which data you wish to prepare and add to a CSV file'
      def prepare(path)
        data_preparation(path)
      end

      desc 'separate CSV_FILE', 'Slice CSV FILE into multiple files for each system each containing specified columns'
      def separate(path)
        data_separation(path)
      end

      desc 'full CSV_FILE', 'Perform all data task in one go. (validate --> prepare --> separate)'
      long_desc <<-LONG_DESC
        Select which data you wish to prepare in a CSV file.\n
        Three steps are performed: \n
        Data Validation --> Data Preparation --> Data Separation.
        LONG_DESC
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

      desc 'stats_3f CSV_FILE', 'Generate an excel file with 3f statistics based on a csv_file with group and voter data'
      def stats_3f(path)
        headers, *rows = read_spreadsheet(path)

        index_area_number = ask_header_index(headers, 'Specify the column with the AREA NUMBER')
        index_area_text = ask_header_index(headers, 'Specify the column with the AREA TEXT')
        index_department = ask_header_index(headers, 'Specify the column with the DEPARTMENT NUMBER')
        index_profession = ask_header_index(headers, 'Specify the column with the PROFESSION NUMBER')
        index_overall_groups = ask_header_index(headers, 'Specify the column with the GROUP MAPPING')

        index_option_label = get_column_index(headers, 'option_label')

        workbook = WriteXLSX.new(ask_output_path('.xlsx', 'overall_3f_stats', 'Pick a name for the OVERALL statistics'))

        bold = workbook.add_format
        bold.set_bold

        unique_departments = rows.map{ |row| row[index_department]}.uniq.sort_by(&:to_i)
        unique_area_numbers = rows.map{ |row| row[index_area_number] }.uniq

        area_number_texts = {}

        unique_area_numbers.each do |number|
          area_number_texts[number] = {}
          rows.each do |row|
            next unless row[index_area_number] == number
            if area_number_texts[number][row[index_area_text]].present?
              area_number_texts[number][row[index_area_text]] += 1
            else
              area_number_texts[number][row[index_area_text]] = 1
            end
          end
        end

        unique_areas = rows.map{ |row| [row[index_area_number], row[index_area_text]] }.uniq{ |number,_text| number}.sort_by{ |number, _text| number.to_i}

        unique_areas = []

        area_number_texts.each do |area_number, value|
          highest_text = ""
          highest_count = 0
          value.each do |text, count|
            if count > highest_count
              highest_text = text
              highest_count = count
            end
          end

          unique_areas << [area_number, highest_text]
        end
        unique_areas = unique_areas.uniq{ |number,_text| number}.sort_by{ |number, _text| number.to_i}

        unique_groups = rows.map{ |row| row[index_overall_groups]}.uniq
        unique_professions = rows.map{ |row| row[index_profession]}.uniq.sort_by(&:to_i)

        # [ARK] Overblik
        overall_worksheet = workbook.add_worksheet('Overblik')
        overall_worksheet.write_row(0, 0, ['Overblik'], bold)
        overall_worksheet.write_row(1, 0, ['','','Stemmer','','Stemmeprocenter'], bold)
        overall_worksheet.write_row(2, 0, ['Navn','Stemmeberettigede','Ja','Nej','Ja','Nej','Stemmepct.'], bold)

        unique_groups.each_with_index do |group, index|
          group_voters = rows.select { |row| row[index_overall_groups] == group}
          area_label = group

          eligible_voters = group_voters.size
          voted_yes = group_voters.select { |row| row[index_option_label] == 'For'}.size
          voted_no = group_voters.select { |row| row[index_option_label] == 'Against'}.size
          votes_total = voted_no+voted_yes

          if votes_total > 0
            overall_worksheet.write_row(index+3, 0, [area_label, eligible_voters, voted_yes, voted_no, (voted_yes/votes_total.to_f) * 100, (voted_no/votes_total.to_f) * 100, (votes_total.to_f/eligible_voters) * 100])
          else
            overall_worksheet.write_row(index+3, 0, [area_label, eligible_voters, 0, 0, 0, 0, 0])
          end
        end

        # SAMLET
        all_voters = rows

        eligible_voters = all_voters.size
        voted_yes = all_voters.select { |row| row[index_option_label] == 'For'}.size
        voted_no = all_voters.select { |row| row[index_option_label] == 'Against'}.size
        votes_total = voted_no+voted_yes

        if votes_total > 0
          overall_worksheet.write_row(unique_groups.size+3, 0, ['Samlet', eligible_voters, voted_yes, voted_no, (voted_yes/votes_total.to_f) * 100, (voted_no/votes_total.to_f) * 100, (votes_total.to_f/eligible_voters) * 100], bold)
        else
          overall_worksheet.write_row(unique_groups.size+3, 0, ['Samlet', eligible_voters, 0, 0, 0, 0, 0], bold)
        end

        # [ARK] Samlet over afdelinger
        joined_departments_worksheet = workbook.add_worksheet('Samlet for alle områder')
        joined_departments_worksheet.write_row(0, 0, ['SAMLET'], bold)
        joined_departments_worksheet.write_row(1, 0, ['','','Stemmer','','Stemmeprocenter'], bold)
        joined_departments_worksheet.write_row(2, 0, ['Navn','Stemmeberettigede','Ja','Nej','Ja','Nej','Stemmepct.'], bold)

        unique_areas.each_with_index do |(area_number, area_text), index|
          area_voters = rows.select { |row| row[index_area_number] == area_number }
          area_label = "#{area_number} #{area_text}"

          eligible_voters = area_voters.size
          voted_yes = area_voters.select { |row| row[index_option_label] == 'For'}.size
          voted_no = area_voters.select { |row| row[index_option_label] == 'Against'}.size
          votes_total = voted_no+voted_yes

          if votes_total > 0
            joined_departments_worksheet.write_row(index+3, 0, [area_label, eligible_voters, voted_yes, voted_no, (voted_yes/votes_total.to_f) * 100, (voted_no/votes_total.to_f) * 100, (votes_total.to_f/eligible_voters) * 100])
          else
            joined_departments_worksheet.write_row(index+3, 0, [area_label, eligible_voters, 0, 0, 0, 0, 0])
          end

        end

        # SAMLET
        all_voters = rows

        eligible_voters = all_voters.size
        voted_yes = all_voters.select { |row| row[index_option_label] == 'For'}.size
        voted_no = all_voters.select { |row| row[index_option_label] == 'Against'}.size
        votes_total = voted_no+voted_yes

        if votes_total > 0
          joined_departments_worksheet.write_row(unique_areas.size+3, 0, ['Samlet', eligible_voters, voted_yes, voted_no, (voted_yes/votes_total.to_f) * 100, (voted_no/votes_total.to_f) * 100, (votes_total.to_f/eligible_voters) * 100], bold)
        else
          joined_departments_worksheet.write_row(unique_areas.size+3, 0, ['Samlet', eligible_voters, 0, 0, 0, 0, 0], bold)
        end


        # [ARK] Per afdeling (afd-101..)
        unique_departments.each do |department|
          worksheet = workbook.add_worksheet("afd-#{department}")
          worksheet.write_row(0, 0, ["Afdeling #{department}"], bold)
          worksheet.write_row(1, 0, ['','','Stemmer','','Stemmeprocenter'], bold)
          worksheet.write_row(2, 0, ['Navn','Stemmeberettigede','Ja','Nej','Ja','Nej','Stemmepct.'], bold)

          unique_areas.each_with_index do |(area_number, area_text), index|
            area_voters = rows.select { |row| row[index_area_number] == area_number && row[index_department] == department}
            area_label = "#{area_number} #{area_text}"

            eligible_voters = area_voters.size
            voted_yes = area_voters.select { |row| row[index_option_label] == 'For'}.size
            voted_no = area_voters.select { |row| row[index_option_label] == 'Against'}.size
            votes_total = voted_no+voted_yes

            if votes_total > 0
              worksheet.write_row(index+3, 0, [area_label, eligible_voters, voted_yes, voted_no, (voted_yes/votes_total.to_f) * 100, (voted_no/votes_total.to_f) * 100, (votes_total.to_f/eligible_voters) * 100])
            else
              worksheet.write_row(index+3, 0, [area_label, eligible_voters, 0, 0, 0, 0, 0])
            end

          end

          # SAMLET
          department_voters = rows.select { |row| row[index_department] == department}

          eligible_voters = department_voters.size
          voted_yes = department_voters.select { |row| row[index_option_label] == 'For'}.size
          voted_no = department_voters.select { |row| row[index_option_label] == 'Against'}.size
          votes_total = voted_no+voted_yes

          if votes_total > 0
            worksheet.write_row(unique_areas.size+3, 0, ['Samlet', eligible_voters, voted_yes, voted_no, (voted_yes/votes_total.to_f) * 100, (voted_no/votes_total.to_f) * 100, (votes_total.to_f/eligible_voters) * 100], bold)
          else
            worksheet.write_row(unique_areas.size+3, 0, ['Samlet', eligible_voters, 0, 0, 0, 0, 0], bold)
          end

        end

        workbook.close

        workbook_group = WriteXLSX.new(ask_output_path('.xlsx', 'profession_3f_stats', 'Pick a name for the PROFESSION statistics'))

        bold = workbook_group.add_format
        bold.set_bold

        # [ARK] Per faggruppe
        unique_groups.each do |group|
          worksheet = workbook_group.add_worksheet(group)
          worksheet.write_row(0, 0, [group], bold)
          worksheet.write_row(1, 0, ['','','Stemmer','','Stemmeprocenter'], bold)
          worksheet.write_row(2, 0, ['Faggruppenr.','Stemmeberettigede','Ja','Nej','Ja','Nej','Stemmepct.'], bold)

          index_fake = 0
          other_voters = []
          unique_professions.each_with_index do |profession, _index|
            profession_voters = rows.select { |row| row[index_profession] == profession && row[index_overall_groups] == group}

            eligible_voters = profession_voters.size
            voted_yes = profession_voters.select { |row| row[index_option_label] == 'For'}.size
            voted_no = profession_voters.select { |row| row[index_option_label] == 'Against'}.size
            votes_total = voted_no+voted_yes

            if votes_total > 0 &&  eligible_voters >= 20
              worksheet.write_row(index_fake+3, 0, [profession, eligible_voters, voted_yes, voted_no, (voted_yes/votes_total.to_f) * 100, (voted_no/votes_total.to_f) * 100, (votes_total.to_f/eligible_voters) * 100])
              index_fake += 1
            else
              other_voters += profession_voters
            end

          end

          # ANDRE
          eligible_voters = other_voters.size
          voted_yes = other_voters.select { |row| row[index_option_label] == 'For'}.size
          voted_no = other_voters.select { |row| row[index_option_label] == 'Against'}.size
          votes_total = voted_no+voted_yes

          if votes_total > 0
            worksheet.write_row(index_fake+4, 0, ['Andre', eligible_voters, voted_yes, voted_no, (voted_yes/votes_total.to_f) * 100, (voted_no/votes_total.to_f) * 100, (votes_total.to_f/eligible_voters) * 100], bold)
          else
            worksheet.write_row(index_fake+4, 0, ['Andre', eligible_voters, 0, 0, 0, 0, 0], bold)
          end

          # SAMLET
          group_voters = rows.select { |row| row[index_overall_groups] == group}

          eligible_voters = group_voters.size
          voted_yes = group_voters.select { |row| row[index_option_label] == 'For'}.size
          voted_no = group_voters.select { |row| row[index_option_label] == 'Against'}.size
          votes_total = voted_no+voted_yes

          if votes_total > 0
            worksheet.write_row(index_fake+5, 0, ['Samlet', eligible_voters, voted_yes, voted_no, (voted_yes/votes_total.to_f) * 100, (voted_no/votes_total.to_f) * 100, (votes_total.to_f/eligible_voters) * 100], bold)
          else
            worksheet.write_row(index_fake+5, 0, ['Samlet', eligible_voters, 0, 0, 0, 0, 0], bold)
          end

        end

        workbook_group.close
      end


      private

      def data_blur(path)
        headers, *rows = read_spreadsheet(path)
        index_stats = ask_header_index(headers, 'Specify the column that should be blurred')
        index_merge = nil
        merge_separator = nil
        blur_threshold = ask_natural_number('Input the blur threshold')
        blur_name = ask("Input name for blurred data (ex. 'Others'): ")
        n_headers = headers
        n_headers += ["blurred_#{headers[index_stats]}"]

        say
        say "Do you want a merge column for the blur name? (ex. '[merge_column_value] - #{blur_name}')", :cyan
        if yes?('Yes (y) / No (n): ')
          say
          index_merge = ask_header_index(headers, 'Specify the column that should be merged with blur name')
          merge_separator = ask('Specify what should separate the values (OBS: use " " to preserve outlying spaces): ')
          merge_separator = merge_separator.gsub(/"/, '')
        end

        dict = Hash.new { |h,k| h[k] = [] }
        rows.each.with_index do |row, line_number|
          key = row[index_stats]
          unless key.blank?
            dict[key] << line_number
          end
        end

        say 'Generating file with blur result', :bold
        ask_output do |csv|
          rows.each do |row|
            value = row[index_stats]
            if dict[value].size <= blur_threshold
              if index_merge.nil?
                row << blur_name
              else
                row << "#{row[index_merge]}#{merge_separator}#{blur_name}"
              end
            else
              row << value
            end
          end

          csv << n_headers
          rows.each do |row|
            csv << row
          end
        end
      end

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
        sample = true
        n_headers = headers

        # Get column indexes of each selected validation type
        validation_types.each do |type|
          case type
          when 0
            index_cpr = ask_header_index(headers, 'Specify the CPR column'); say
            n_headers += ['cpr_valid']
          when 1
            index_email = ask_header_index(headers, 'Specify the EMAIL column'); say
            n_headers += ['email_valid']
          when 2
            index_addr = ask_header_index(headers, 'Specify the ADDRESS column')
            say 'Address validation is very time consuming, consider only using a sample!', :yellow
            sample = yes?('Do you want to use a sample (25) of the addresses when validating?', :yellow); say
            n_headers += ['address_found']
          when 3
            index_phone = ask_header_index(headers, 'Specify the PHONE NUMBER column'); say
            n_headers += ['phone_valid']
          end
        end

        check_empty = yes?('Do you wants to check for empty values in other fields?'); say
        indexes_empty_check = ask_header_indexes(headers, 'Specify which columns you want to check for empty values') if check_empty
        say

        dawa_client = AionCLI::DAWAClient.instance

        # Iterate through selected validations and perform validation --> output to csv

        say 'Generating file with validation result', :bold
        ask_output do |csv|
          say 'Performing validation...', :cyan
          csv << n_headers

          # CPR validation
          if validation_types.include?(0)

            # Build doublet index
            dict = Hash.new { |h,k| h[k] = [] }
            rows.each.with_index do |row, line_number|
              key = row[index_cpr]
              unless key.blank?
                dict[key] << line_number
              end
            end

            rows.each do |row|
              cpr = row[index_cpr]
              if cpr.blank?
                counts_validation[:cpr_empty] += 1
                result = "false empty"
              elsif dict[cpr].size > 1
                counts_validation[:cpr_doublets] += 1
                result = "false doublet"
              else
                valid = validate_cpr(cpr)
                valid ? result = "true" : result = "false format"
                counts_validation[:cpr_invalid] += 1 unless valid
              end
              row << result
            end
          end

          #EMAIL validation
          if validation_types.include?(1)
            rows.each do |row|
              email = row[index_email]
              if email.blank?
                counts_validation[:email_empty] += 1
                result = "false empty"
              else
                valid = validate_email(email)
                valid ? result = "true" : result = "false format"
                counts_validation[:email_invalid] += 1 unless valid
              end
              row << result
            end
          end

          #ADDRESS validation
          if validation_types.include?(2)
            addr_tested = 0
            rows.each do |row|
              result = ""    # bedre måde?
              addr = row[index_addr]
              if addr.blank?
                counts_validation[:addr_empty] += 1
                result = "false empty"
              else
                unless addr_tested > 25 && sample
                  valid = validate_addr(addr, dawa_client)
                  valid ? result = "true" : result = "false format"
                  counts_validation[:addr_not_found] += 1 unless valid
                  addr_tested += 1
                end
              end
              row << result
            end
          end

          #PHONE NUMBER validation
          if validation_types.include?(3)
            rows.each do |row|
              phone = row[index_phone]
              if phone.blank?
                counts_validation[:phone_empty] += 1
                result = "false empty"
              else
                valid = validate_phone_number(phone)
                valid ? result = "true" : result = "false format"
                counts_validation[:phone_invalid] += 1 unless valid
              end
              row << result
            end
          end

          rows.each do |row|
            csv << row
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
            index_cpr = ask_header_index(headers, 'Specify the CPR column'); say
            n_headers += ["#{headers[index_cpr]}_cleaned"]
          when 1
            index_phone = ask_header_index(headers, 'Specify the PHONE NUMBER column'); say
            n_headers += ["#{headers[index_phone]}_cleaned"]
          when 2
            index_dob = ask_header_index(headers, 'Specify the DATE OF BIRTH column'); say
            n_headers += ["#{headers[index_dob]}_cleaned"]

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
        say 'Generating file with preparation results', :bold

        result_file = ask_output_path

        output result_file do |csv|
          say 'Performing preparation...', :cyan

          dict_failed = []

          # -------- Cleaning jobs --------

          #CPR cleaning
          if clean_types.include?(0)
            rows.each.with_index do |row, line_number|
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

          puts dict_failed
          if dict_failed.any?
            #Gather fails in a csv
            say
            say 'Generating file with faulty cpr rows', :bold
            faulty_file = ask_output_path
            output faulty_file do |csv_failed|
              csv_failed << n_headers
              dict_failed.uniq.each do |line_number|
                csv_failed << rows[line_number]
              end
            end
          end
        end
        result_file
      end

      def data_separation(path)
        rows = read_spreadsheet(path)

        # Select validation commands
        command_headers = ['Votes','Cards','Candidacy','[ Skip ]']
        slice_types = ask_header_indexes(command_headers, 'Specify what systems you need files for'); say
        customer = ask("Input customer initials for file naming (i.e. AV, JØP, HK, ..):")

        return if slice_types.include?(3)
        slice_types.each do |t|
          file_suffix = command_headers[t]
          say
          say  "Slicing file for #{file_suffix}...", [:cyan, :bold]
          indexes = ask_header_indexes(rows.first, "Pick the columns to keep")
          slice_file(rows, indexes, customer, file_suffix)
        end
      end
    end
  end
end
